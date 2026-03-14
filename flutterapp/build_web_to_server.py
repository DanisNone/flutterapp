import os
import paramiko


SERVER_IP = "62.109.7.138"
USERNAME = "root"
PASSWORD = "Danis291@"
REMOTE_DIR = "/root/flutter_app"
LOCAL_DIR = "build/web"


def build_flutter():
    os.system("flutter build web -v")


def mkdir_p(sftp, remote_directory):
    dirs = remote_directory.split("/")
    path = ""

    for d in dirs:
        if d == "":
            continue

        path += "/" + d
        try:
            sftp.stat(path)
        except Exception:
            try:
                sftp.mkdir(path)
            except Exception:
                pass


def upload():
    ssh = paramiko.Transport((SERVER_IP, 22))
    ssh.connect(username=USERNAME, password=PASSWORD)

    sftp = paramiko.SFTPClient.from_transport(ssh)

    for root, dirs, files in os.walk(LOCAL_DIR):
        for file in files:
            local_path = os.path.join(root, file).replace("\\", "/")

            remote_path = os.path.join(
                REMOTE_DIR,
                os.path.relpath(local_path, LOCAL_DIR)
            ).replace("\\", "/")

            remote_dir = os.path.dirname(remote_path)

            mkdir_p(sftp, remote_dir)

            print(local_path)
            sftp.put(local_path, remote_path)

    sftp.close()
    ssh.close()


build_flutter()
upload()
