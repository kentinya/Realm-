#!/usr/bin/env python3
import os
import sys
import subprocess

# 从命令行参数获取下载根目录、文件/文件夹名称和种子分类

root = sys.argv[1]  # qBittorrent 下载的根目录
file = sys.argv[2]           # 下载的文件或文件夹名称
category = sys.argv[3]       # qBittorrent 分类名称
#root = "D:\\B\\"
#file = "D:\\B\\C\\"
#category = "剧集"
# 基础目录，所有的 .strm 文件都会放在这个目录的子文件夹中
base_target_folder = "/opt/media/"

# 根据分类名称设置目标文件夹
target_category_folder = os.path.join(base_target_folder, category)

# 如果分类目标文件夹不存在，创建它
if not os.path.exists(target_category_folder):
    os.makedirs(target_category_folder)

# 创建 .strm 文件的函数
def process_file(file_path, target_base, root_path):
    """_summary_

    Args:
        file_path (_type_): _description_
        target_base (_type_): _description_
        root_path (_type_): _description_
    """    
    
    relative_path = os.path.relpath(file_path, root_path)
    target_path = os.path.join(target_base, relative_path)
    extension_name= os.path.splitext(target_path)
    dir_name = os.path.dirname(target_path)
    if not os.path.exists(dir_name):
        os.makedirs(dir_name)    
    if target_path.endswith(tuple(['.mp4', '.mkv', '.avi','.ts'])):
        strm_file_path = extension_name[0] + '.strm'
        with open(strm_file_path, 'w') as strm_file:
            strm_file.write(file_path)
    target_base = target_category_folder

def process_dir(folder_path, target_category_folder, root_path):
    """_summary_

    Args:
        folder_path (_type_): _description_
        target_base (_type_): _description_
        root_path (_type_): _description_
    """    
    for root,dirs,files in os.walk(folder_path):
        for file in files:
            
            relative_path = os.path.relpath(root, root_path)
            target_base = os.path.join(target_category_folder, relative_path)
            file_path = os.path.join(root, file)
            process_file(file_path, target_base, root)
        



if os.path.isfile(file):
    process_file(file, target_category_folder, root)
elif os.path.isdir(file):
    process_dir(file, target_category_folder, root)




