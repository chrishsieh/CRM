local PipelineBuild = {
  kind: "pipeline",
  name: "Build&Test",
  steps: [
    {
      name: "build",
      image: "devilbox/php-fpm:7.2-work",
      environment: [
        {FORWARD_PORTS_TO_LOCALHOST: "3306:mysql:3306, 80:crm:80"},
        {PHP_MODULES_DISABLE: "xdebug"}
      ],
      commands: [
        "export DB=mysql",
        "php --version",
        "node --version",
        "composer --version",
        "apt-get update",
        "apt-get install -y ruby-full",
        "gem install sass -v 3.4.25",
        "chmod +x ./travis-ci/*.sh",
        "chmod +x ./scripts/*.sh",
        "cp BuildConfig.json.example BuildConfig.json",
        "chown -R devilbox:devilbox /drone/src/src",
        "npm install --unsafe-perm",
        "npm run composer-install",
        "npm run orm-gen",
      ]
    },
    {
      name: "store-cache",
      image: "chrishsieh/drone-volume-cache",
      environment: [
        {PLUGIN_MOUNT: "drone-ci"},
        {PLUGIN_REBUILD: "true"}
      ],
      volumes: [
        {
          name: "cache",
          path: "/cache"
        }
      ]
    },
    {
      name: "Test-7.1",
      image: "devilbox/php-fpm:7.1-work",
      environment: [
        {FORWARD_PORTS_TO_LOCALHOST: "3306:mysql:3306"},
        {PHP_MODULES_DISABLE: "xdebug"},
        {TEST_PHP_VER: "7.1"}
      ],
      commands: [
        "cp ./drone-ci/tests-run.sh ./scripts/tests-run.sh",
        "cp ./drone-ci/bootstrap.php ./tests/bootstrap.php",
        "npm run tests-install",
        'mysql --user=root --password=churchcrm --host=mysql -e "drop database IF EXISTS churchcrm_test;"',
        "mysql --user=root --password=churchcrm --host=mysql -e 'create database IF NOT EXISTS churchcrm_test;'",
        "mysql --user=root --password=churchcrm --host=mysql churchcrm_test < src/mysql/install/Install.sql;",
        "mysql --user=root --password=churchcrm --host=mysql churchcrm_test < demo/ChurchCRM-Database.sql;",
        'sed -i "s/web_server/crm$TEST_PHP_VER/g" ./drone-ci/Config.php',
        'sed -i "s/web_server/crm$TEST_PHP_VER/g" ./drone-ci/behat.yml',
        "cp ./drone-ci/Config.php ./src/Include/Config.php",
        "cp ./drone-ci/behat.yml ./tests/behat/behat.yml",
        "npm run test",
      ]
    },
    {
      name: "restore-cache-7.1",
      image: "chrishsieh/drone-volume-cache",
      environment: [
        {PLUGIN_MOUNT: "drone-ci"},
        {PLUGIN_RESTORE: "true"}
      ],
      volumes: [
        {
          name: "cache",
          path: "/cache"
        }
      ]
    }
  ],
  services: [
    {
      name: "mysql",
      image: "cytopia/mariadb-10.3",
      environment: [
        {MYSQL_ROOT_PASSWORD: "churchcrm"}
      ]
    },
    {
      name: "php7.2",
      image: "devilbox/php-fpm:7.2-work",
      environment: [
        {FORWARD_PORTS_TO_LOCALHOST: "3306:mysql:3306, 80:crm7.2:80"},
        {PHP_MODULES_DISABLE: "xdebug"}
      ],
      commands: [
        "mkdir /var/www/default",
        "ln -s /drone/src/src/ /var/www/default/htdocs",
        "/docker-entrypoint.sh",
      ],
      working_dir: "/var/www/default"
    },
    {
      name: "crm7.2",
      image: "devilbox/apache-2.4",
      environment: [
        {PHP_FPM_ENABLE: 1},
        {PHP_FPM_SERVER_ADDR: "php7.2"},
        {PHP_FPM_SERVER_PORT: 9000},
        {MAIN_VHOST_ENABLE: 1},
        {MAIN_VHOST_SSL_CN: "crm7.2"}
      ],
      commands: [
        "rm -rf /var/www/default/htdocs}",
        "ln -s /drone/src/src/ /var/www/default/htdocs}",
        "/docker-entrypoint.sh",
      ],
      working_dir: "/var/www/default"
    },
    {
      name: "selenium",
      image: "selenium/standalone-chrome",
      volumes: [
        {
          name: "shm",
          path: "/dev/shm:/dev/shm"
        }
      ]
    }
  ],
  volumes: [
    {
      name: "cache",
      temp: "{}"
    }
  ]
};

[
  PipelineBuild
]
