# Docker Image Builder Script

## Introduction

This script automates the creation, building, tagging, and pushing of Docker images based on specified base images and tags.

## 介绍

此脚本自动化创建、构建、打标签和推送基于指定基础镜像和标签的 Docker 镜像。

## Usage

1. Make sure you have Docker installed on your system.
2. Update the script with the desired base images and tags.
3. Run the script to create Dockerfiles, build images, and push them to the registry.

## 使用方法

1. 确保您的系统已安装 Docker。
2. 使用所需的基础镜像和标签更新脚本。
3. 运行脚本以创建 Dockerfile、构建镜像并将其推送到注册表。

## Cleanup

After building and pushing the images, you can run the script with the `clean_up` function to remove the Dockerfiles, intermediate images, and build cache produced by this script.

## 清理

在构建和推送镜像后，您可以运行带有 `clean_up` 函数的脚本，以删除此脚本生成的 Dockerfile、中间镜像和构建缓存。

## Notes

* Ensure you have the necessary permissions to build and push Docker images.
* This script is designed to work with the specified base images and tags. Modify it according to your requirements.

## 注意事项

* 确保您具有构建和推送 Docker 镜像的必要权限。
* 此脚本旨在与指定的基础镜像和标签配合使用。根据您的需求进行修改。
