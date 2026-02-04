import socket
import threading
import time
import os


class EnhancedBroadcastServer:
    def __init__(self, host="192.168.10.7", port=8080):
        self.host = host
        self.port = port
        self.clients = []  # 存储客户端socket
        self.client_info = (
            {}
        )  # 存储客户端信息 {socket: {"address": addr, "name": name}}
        self.lock = threading.Lock()

        # 创建文件上传目录
        self.upload_dir = "server_uploads"
        if not os.path.exists(self.upload_dir):
            os.makedirs(self.upload_dir)

    def broadcast_to_all(self, data, source_socket=None):
        """广播消息给所有客户端"""
        with self.lock:
            # ← 添加1秒延迟，确保分开
            disconnected = []

            for client in self.clients:
                if client != source_socket:
                    try:
                        client.send(data)
                        client.send(b"")
                    except:
                        disconnected.append(client)

            # 清理断开连接
            for client in disconnected:
                self.remove_client(client)

    def remove_client(self, client_socket):
        """移除客户端"""
        with self.lock:
            if client_socket in self.clients:
                self.clients.remove(client_socket)

                # 获取客户端信息用于日志
                info = self.client_info.get(client_socket, {})
                addr = info.get("address", "unknown")
                print(f"🔌 移除客户端: {addr}")

                # 删除客户端信息
                if client_socket in self.client_info:
                    del self.client_info[client_socket]

    def save_file_safely(self, filename, file_data, expected_size):
        """简单保存文件 - 直接使用原始文件名"""

        # 直接使用原始文件名
        filepath = os.path.join(self.upload_dir, filename)

        # 保存文件
        with open(filepath, "wb") as f:
            f.write(file_data[:expected_size])

        print(f"📁 文件保存: {filename} ({len(file_data[:expected_size])} 字节)")
        return filepath

    def handle_client(self, client_socket, address):

        # 客户端信息
        global file_size
        client_info = f"{address[0]}:{address[1]}"
        print(f"🔗 客户端连接: {client_info}")

        # 添加到客户端列表
        with self.lock:
            self.clients.append(client_socket)
            self.client_info[client_socket] = {
                "address": client_info,
                "name": f"用户{len(self.clients)}",
                "connect_time": time.time(),
            }

        # 发送欢迎消息

        # 广播加入消息
        join_msg = (
            f"【系统】用户 {client_info} 加入聊天室，当前在线: {len(self.clients)}人\n"
        )
        self.broadcast_to_all(join_msg.encode("utf-8"), source_socket=client_socket)
        print(f"📢 {join_msg.strip()}")

        # 状态机
        STATE_NORMAL = 0
        STATE_RECEIVING_FILE = 1
        current_state = STATE_NORMAL

        file_data = b""
        expected_size = 0
        received_size = 0
        filename = ""

        try:
            while True:
                try:
                    # 接收数据
                    data = client_socket.recv(4096)
                    if not data:
                        break

                    # 状态机处理
                    if current_state == STATE_NORMAL:
                        # 检查文件头部
                        if b"FILE|" in data:
                            header_end = data.find(b"|", data.find(b"FILE|"))
                            header_end = data.find(b"|", header_end + 1)
                            header_end = data.find(b"|", header_end + 1)
                            header_end = data.find(b"|", header_end + 1)

                            if header_end != -1:
                                header = data[: header_end + 1].decode(
                                    "utf-8", errors="ignore"
                                )
                                parts = header.split("|")
                                if len(parts) >= 4:
                                    filename = parts[1]
                                    expected_size = int(parts[2])
                                    duration = int(parts[3])
                                    print(
                                        f"📎 开始接收文件: {filename} ({expected_size} 字节) {duration}/s"
                                    )

                                    current_state = STATE_RECEIVING_FILE
                                    file_data = b""
                                    received_size = 0

                                    # 提取头部后的数据
                                    file_chunk = data[header_end + 1 :]
                                    if file_chunk:
                                        file_data = file_chunk
                                        received_size = len(file_chunk)

                                    continue

                    elif current_state == STATE_RECEIVING_FILE:
                        file_data += data
                        received_size += len(data)

                        print(f"📥 文件接收进度: {received_size}/{expected_size}")

                        if received_size >= expected_size:
                            print(f"✅ 文件接收完成!")

                            # 保存文件
                            filepath = self.save_file_safely(filename, file_data, expected_size)
                            # 通知发送者

                            # 📢 直接广播文件头给所有人
                            file_size = os.path.getsize(filepath)
                            file_header =f"FILE|{filename}|{duration}|{file_size}|\n"

                            # 广播给所有客户端
                            self.broadcast_to_all(
                                 file_header.encode("utf-8"), source_socket=client_socket
                            )

                            # 修改这部分代码
                            try:
                                # 先获取文件大小

                                print(f"📊 准备发送文件: {filename} ({file_size} 字节)")

                                # 显示进度：开始发送
                                print(f"🚀 开始发送文件...")

                                with open(filepath, "rb") as f:
                                    # 分块读取和发送，显示进度
                                    CHUNK_SIZE = 4096  # 4KB每块
                                    total_sent = 0

                                    while True:
                                        chunk = f.read(CHUNK_SIZE)
                                        if not chunk:
                                            break

                                        # 发送数据块
                                        self.broadcast_to_all(
                                            chunk,
                                            source_socket=client_socket,
                                        )
                                        total_sent += len(chunk)

                                        # 显示发送进度
                                        progress = (total_sent / file_size) * 100
                                        print(
                                            f"📤 发送进度: {total_sent}/{file_size} ({progress:.1f}%)"
                                        )

                                print(f"✅ 文件发送完成: {filename}")

                            except Exception as e:
                                print(f"❌ 读取文件失败: {e}")
                            # 重置状态
                            current_state = STATE_NORMAL
                            file_data = b""
                            expected_size = 0
                            received_size = 0
                            filename = ""

                            continue

                    # ============ 文字消息处理 ============
                    if current_state == STATE_NORMAL:
                        try:
                            text = data.decode("utf-8").strip()

                            if text:
                                # 获取客户端昵称
                                with self.lock:
                                    nickname = self.client_info.get(
                                        client_socket, {}
                                    ).get("name", client_info)

                                broadcast_msg = f"{text}\n"

                                # 广播消息
                                self.broadcast_to_all(
                                    broadcast_msg.encode("utf-8"),
                                    source_socket=client_socket,
                                )

                                print(f"💬 {broadcast_msg.strip()}")

                        except UnicodeDecodeError:
                            print(f"🔠 收到无法解码的数据来自 {client_info}")

                except socket.timeout:
                    print(f"⏰ 客户端 {client_info} 超时")
                    break

        except Exception as e:
            print(f"❌ 客户端 {client_info} 错误: {e}")

        finally:
            # 客户端断开
            leave_msg = f"👋 {client_info} 离开了聊天室\n"

            print(f"📢 {leave_msg.strip()}")

            self.remove_client(client_socket)
            client_socket.close()

    def start(self):
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server_socket.bind((self.host, self.port))
        server_socket.listen(5)

        print("=" * 60)
        print(f"🚀 增强版聊天服务器已启动")
        print(f"📍 地址: {self.host}:{self.port}")
        print(f"⏰ 时间: {time.strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 60)
        print("等待客户端连接...")

        try:
            while True:
                client_socket, address = server_socket.accept()
                thread = threading.Thread(
                    target=self.handle_client, args=(client_socket, address)
                )
                thread.daemon = True
                thread.start()

        except KeyboardInterrupt:
            print("\n\n🛑 服务器正在关闭...")
        finally:
            server_socket.close()
            print("✅ 服务器已关闭")


if __name__ == "__main__":
    # 测试客户端连接：
    # 1. 使用 telnet: telnet 192.168.10.2 8080
    # 2. 使用 netcat: nc 192.168.10.2 8080

    server = EnhancedBroadcastServer()
    server.start()
