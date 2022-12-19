<!-- omit in toc -->
# vault formula

Формула для установки и настройки HashiCorp Vault.

* [Использование](#использование)
* [Доступные стейты](#доступные-стейты)
  * [vault](#vault)
  * [vault.repo](#vaultrepo)
  * [vault.repo.clean](#vaultrepoclean)
  * [vault.install](#vaultinstall)
  * [vault.binary.install](#vaultbinaryinstall)
  * [vault.binary.clean](#vaultbinaryclean)
  * [vault.package.install](#vaultpackageinstall)
  * [vault.package.clean](#vaultpackageclean)
  * [vault.config](#vaultconfig)
  * [vault.config.tls](#vaultconfigtls)
  * [vault.service](#vaultservice)
  * [vault.service.install](#vaultserviceinstall)
  * [vault.service.clean](#vaultserviceclean)
  * [vault.shell\_completion](#vaultshell_completion)
  * [vault.shell\_completion.clean](#vaultshell_completionclean)
  * [vault.shell\_completion.bash](#vaultshell_completionbash)
  * [vault.shell\_completion.bash.install](#vaultshell_completionbashinstall)
  * [vault.shell\_completion.bash.clean](#vaultshell_completionbashclean)

## Использование

* Создаем pillar с данными, см. `pillar.example` для качестве примера, привязываем его к хосту в pillar top.sls.
* ВАЖНО: В pillar указываем `vault.install: true` иначе установка не будет произведена
* Применяем стейт на целевой хост `salt 'vault-01*' state.sls vault saltenv=base pillarenv=base`.
* Прикрепляем формулу к хосту в state top.sls, для выполнения оной при запуске `state.highstate`.

__ВНИМАНИЕ__  

После установки Vault еще не инициализирован, для дальнейшей работы ознакомьтесь с документацией, можно начать отсюда - [Initializing the Vault](https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-deploy#initializing-the-vault).

## Доступные стейты

### vault

Мета стейт, выполняет все необходимое для настройки сервиса на отдельном хосте.

### vault.repo

Стейт для настройки официального репозитория HashiCorp <https://www.hashicorp.com/blog/announcing-the-hashicorp-linux-repository>

### vault.repo.clean

Стейт для удаления репозитория, используйте с осторожностью, т.к. данный репозиторий используется для всех продуктов HashiCorp.

### vault.install

Вызывает стейт для установки Vault в зависимости от значения пиллара `use_upstream`:

* `binary` или `archive`: установка из архива `vault.binary.install`
* `package` или `repo`: установка из пакетов `vault.package.install`

### vault.binary.install

Установка Vault из архива

### vault.binary.clean

Удаление Vault установленного из архива

### vault.package.install

Установка Vault из пакетов

### vault.package.clean

Удаление Vault установленного из пакетов

### vault.config

Создает конфигурационный файл. Создает самоподписанный сертификат, или устанавливает готовый сертификат. Запускает сервис.

### vault.config.tls

Управление TLS сертификатами для Vault, при `tls.self_signed: true` будут сгенерированы ключ и самоподписной сертификат и сохранены по путям указанным в `vault.config.data.listener.tcp.tls_key_file`, `vault.config.data.listener.tcp.tls_cert_file`. При `tls:self_signed: false` и наличии данных в `tls:key_file_source`, `tls:cert_file_source` существующие ключ и сертификат будут скопированы по путям указанным `vault.config.data.listener.tcp.tls_key_file`, `vault.config.data.listener.tcp.tls_cert_file`.

### vault.service

Управляет состоянием сервиса vault, в зависимости от значений пилларов `vault.service.status`, `vault.service.on_boot_state`.

### vault.service.install

Устанавливает файл сервиса Vault, на данный момент поддерживается только одна система инициализации - `systemd`.

### vault.service.clean

Останавливает сервис, выключает запуск сервиса при старте ОС, удаляет юнит файл `systemd`.

### vault.shell_completion

Вызывает стейты `vault.shell_completion.*` на данный момент только `vault.shell_completion.bash`.

### vault.shell_completion.clean

Вызывает стейты `vault.shell_completion.*.clean` на данный момент только `vault.shell_completion.bash.clean`.

### vault.shell_completion.bash

Вызывает стейт `vault.shell_completion.bash.install`

### vault.shell_completion.bash.install

Устанавливает автодополнение для bash

### vault.shell_completion.bash.clean

Удаляет автодополнение для bash
