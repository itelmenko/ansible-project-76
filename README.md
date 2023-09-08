### Hexlet tests and linter status:
[![Actions Status](https://github.com/itelmenko/ansible-project-76/workflows/hexlet-check/badge.svg)](https://github.com/itelmenko/ansible-project-76/actions)

# Deploy Docker-образов с помощью Ansible

[TOC]

## Необходимая инфраструктура и основные возможности

Проект с помощью Ansible разворачивает  web-сервис Redmine из Docker-контейнера. А также устанавливает Datadog Agent и настраивает проверку http_check.

Используются следующие дополнительные коллекции Ansible:
* https://docs.ansible.com/ansible/latest/collections/community/docker/docker_container_module.html
* https://galaxy.ansible.com/DataDog/ddd

Необходимая инфраструктура создается через интерфейс облачного провайдера. Например, Digital Ocean (DO).

Потребуется следующие составляющие:

* Два сервера (droplets) на базе Ubuntu с установленным Docker (Такая опция есть у DO)
* Балансировщик нагрузки (Load Balancer), к которому подключены эти серверы
* Кластер БД MySQL. В настройках разрешить доступ к серверу БД только с этих серверов

При создании серверов нужно указать свои публичные ключи для ssh.

Необходимо создать БД в MySQL:

```sql
ALTER DATABASE `redmine`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;
```

При развертывании Redmine может вызывать следующую ошибку:

> redmine-redmine-1  | Mysql2::Error: Unable to create or change a table without a primary key, when the system variable 'sql_require_primary_key' is set. Add a primary key to the table or unset this variable to avoid this message. Note that tables without a primary key can cause performance problems in row-based replication, so please consult your DBA before changing this setting.

Чтобы этого не происходило необходимо воспользоваться API DO, как описано [тут](https://stackoverflow.com/questions/62418099/unable-to-create-or-change-a-table-without-a-primary-key-laravel-digitalocean).

А именно: создать ключ API, узнать ID кластера БД, и применить настройку `{"config": { "sql_require_primary_key": false }}`. Запрос отправляется на `https://api.digitalocean.com/v2/databases/{YOUR_DATABASE_CLUSER_ID}/config` с передачей Bearer token.

## Регистрация и делегирование домена

Для обращения к приложению необходимо использовать домен, делегированный в DO и с A-записью, указывающей на IP Load Balancer. В примере используется домен [telmenko.ru](https://itelmenko.ru).

Чтобы работало обращение и по http и по https необходимо подключить Lets Encrypt SSL-сертификат в настройках проброски портов Load Balancer.

Проброска должна выглядеть так:

```
HTTP on port 80  HTTP on port 80
HTTPS on port 443  HTTP on port 80
```

## Список серверов для развертывания

Серверы (дроплеты) перечислены в файле инвентаризации inventory.ini. В секции webservers.
Здесь указаны IP адреса, которые должны соответствовать адресам дроплетов.

## Настройки Datadog

Для мониторинга серверов используется сервис Datadog. Необходима регистрация в нем и получение API ключа.

Для настроек агента Datadog через Ansible используется [коллекция](https://galaxy.ansible.com/DataDog/ddd). Инструкция - [здесь](https://github.com/ansible-collections/Datadog/blob/main/README.md).
Описание настройки http_check - [здесь](https://docs.datadoghq.com/integrations/http_check/).

После настройки данные мониторинга будут доступны по адресу https://app.datadoghq.eu/infrastructure/map?fillby=avg%3Acpuutilization&groupby=availability-zone

Для проверки состояния агента на сервере (при надобности) необходимо выполнить следующую команду:

```
datadog-agent status
```

Если в ней будет строка типа `API key ending with 12430: API Key invalid`, то, вероятно, дело в домене datadog. Нужно выбрать верный домен (из верной зоны) и указать в group_vars.

Для проверки работы http_check на сервере (при надобности) используется команда:

```
datadog-agent check http_check
```

## Основные настройки и команды запуска

Основные переменные описаны в файле group_vars/webservers/common.yml
Переменные с ключами и паролями - в файле group_vars/webservers/vault.yml

Последний для редактирования нужно расшифровать командой `make config`
Структура файла такая:

```
db_password: AVN****************RVfDL
redmine_secret: Gjsd***************7ssfF
datadog_key: 53cf**************2430
```

Для упрощения ввода команд в проекте имеется Makefile.

В нем есть следующие команды:

```shell
make all # Запуск всего playbook с подготовкой, развертыванием Redmine и настройкой Datadog
make prepare # Только подготовка (установка pip и модуля для работы с Docker)
make deploy # Развертывание Redmine
make datadog # Настройка Datadog
make config # Редактирование зашифрованного конфигурационного файла
```