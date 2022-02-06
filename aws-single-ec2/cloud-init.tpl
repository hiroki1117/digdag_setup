#cloud-config

timezone: Asia/Tokyo
locale: ja_JP.utf8
users:
    - default
    - name: digdag
      primary_group: digdag
      groups: users

package_upgrade: true
packages:
    - java-1.8.0-openjdk
    - docker

