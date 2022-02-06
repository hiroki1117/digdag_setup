#cloud-config

timezone: Asia/Tokyo
locale: ja_JP.utf8
users:
    - default
    - name: digdag
      primary_group: digdag
      groups: users,docker

    - name: ec2-user
      primary_group: ec2-user
      groups: users,docker

package_upgrade: true
packages:
    - java-1.8.0-openjdk
    - docker

write_files:
    - path: /home/digdag/.docker/config.json
      content: |
        {
          "credHelpers": {
            "${ecr_repository_url}": "ecr-login"
          }
        }
      owner: 'digdag:digdag'
      permissions: '0744'
      defer: true
    - path: /home/ec2-user/.docker/config.json
      content: |
        {
          "credHelpers": {
            "${ecr_repository_url}": "ecr-login"
          }
        }
      owner: 'ec2-user:ec2-user'
      permissions: '0744'
      defer: true
    - path: /usr/local/etc/digdag.properties
      content: |
        server.bind=0.0.0.0
        database.type=postgresql
        database.user=${db_user}
        database.password=${db_password}
        database.host=${db_host}
        database.database=${db_database}
        database.maximumPoolSize=${db_max_pool_size}
        archive.type=s3
        archive.s3.bucket=${s3_bucket}
        archive.s3.path=${archive_s3_path}
        log-server.type=s3
        log-server.s3.bucket=${s3_bucket}
        log-server.s3.path=${log_server_s3_path}
        digdag.secret-encryption-key=${secret_encryption_key}
        config.http.max_stored_response_content_size=100000
        executor.task_ttl=3d
        api.max_archive_total_size_limit=16777216
      owner: 'root:root'
      permissions: '0744'
      defer: true
    - path: /etc/systemd/system/digdag.service
      content: |
        [Unit]
        Description=digdag

        [Service]
        Type=simple
        User=digdag
        Restart=always
        RestartSec=5
        TimeoutStartSec=30s
        WorkingDirectory=/opt/digdag/
        KillMode=process

        ExecStart=/usr/local/bin/digdag server --memory -b 0.0.0.0 -n 80

        [Install]
        WantedBy=multi-user.target
      owner: 'root:root'
      permissions: '0755'
      defer: true

runcmd:
    # docker-credential-gcr
    - yum install amazon-ecr-credential-helper
    # digdag
    - curl -s -o /usr/local/bin/digdag --create-dirs -L https://dl.digdag.io/digdag-0.10.4
    - chmod +x /usr/local/bin/digdag

    - systemctl enable docker
    - systemctl start docker

