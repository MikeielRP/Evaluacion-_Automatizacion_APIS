Feature: Regresion - Billetera Digital

  Background:
    * def authUrl = 'http://134.209.211.10:4001'
    * def walletUrl = 'http://134.209.211.10:4002'
    * def transactionUrl = 'http://134.209.211.10:4003'
    * def adminUrl = 'http://134.209.211.10:4004'
    * def generarCelular = function(){ return '9' + Math.floor(10000000 + Math.random() * 90000000) }

  Scenario: Escenario 1 - Registro de usuarios y asignacion de saldo
    * def telefonoEmisor = generarCelular()
    * def telefonoReceptor = generarCelular()
    * def correoEmisor = 'emisor' + telefonoEmisor + '@test.com'
    * def correoReceptor = 'receptor' + telefonoReceptor + '@test.com'
    * def cuerpoEmisor = ({ phone: telefonoEmisor, fullName: 'Usuario Emisor', email: correoEmisor, pin: '123456' })
    Given url authUrl
    And path 'auth', 'v1', 'register'
    And header x-channel = 'POSTMAN'
    And request cuerpoEmisor
    When method post
    Then status 201
    And match response.user.id == '#string'
    * def idEmisor = response.user.id
    * def cuerpoReceptor = ({ phone: telefonoReceptor, fullName: 'Usuario Receptor', email: correoReceptor, pin: '123456' })
    Given url authUrl
    And path 'auth', 'v1', 'register'
    And header x-channel = 'POSTMAN'
    And request cuerpoReceptor
    When method post
    Then status 201
    And match response.user.id == '#string'
    * def idReceptor = response.user.id
    * def cuerpoLoginEmisor = ({ phone: telefonoEmisor, pin: '123456' })
    Given url authUrl
    And path 'auth', 'v1', 'login'
    And header x-channel = 'POSTMAN'
    And request cuerpoLoginEmisor
    When method post
    Then status 200
    And match response.expiresIn == 3600
    * def tokenEmisor = response.token
    * def cuerpoLoginReceptor = ({ phone: telefonoReceptor, pin: '123456' })
    Given url authUrl
    And path 'auth', 'v1', 'login'
    And header x-channel = 'POSTMAN'
    And request cuerpoLoginReceptor
    When method post
    Then status 200
    And match response.expiresIn == 3600
    * def tokenReceptor = response.token
    * def cuerpoDepositoEmisor = { amount: 1000 }
    Given url walletUrl
    And path 'wallet', 'v1', 'deposit'
    And header x-channel = 'POSTMAN'
    And header Authorization = 'Bearer ' + tokenEmisor
    And request cuerpoDepositoEmisor
    When method post
    Then status 200
    And match response.success == true
    And match response.newBalance == 1000

    * def cuerpoDepositoReceptor = { amount: 100 }
    Given url walletUrl
    And path 'wallet', 'v1', 'deposit'
    And header x-channel = 'POSTMAN'
    And header Authorization = 'Bearer ' + tokenReceptor
    And request cuerpoDepositoReceptor
    When method post
    Then status 200
    And match response.success == true
    And match response.newBalance == 100
    Given url walletUrl
    And path 'wallet', 'v1', 'balance'
    And header x-channel = 'POSTMAN'
    And header Authorization = 'Bearer ' + tokenEmisor
    When method get
    Then status 200
    And match response.balance == 1000
    * def saldoEmisorInicial = response.balance

    Given url walletUrl
    And path 'wallet', 'v1', 'balance'
    And header x-channel = 'POSTMAN'
    And header Authorization = 'Bearer ' + tokenReceptor
    When method get
    Then status 200
    And match response.balance == 100
    * def saldoReceptorInicial = response.balance
    * def datos = ({ telefonoEmisor: telefonoEmisor, telefonoReceptor: telefonoReceptor, idEmisor: idEmisor, idReceptor: idReceptor, saldoEmisorInicial: saldoEmisorInicial, saldoReceptorInicial: saldoReceptorInicial })
    * karate.write(datos, 'datos.json')

  Scenario: Escenario 2 - Transferencia del Emisor al Receptor
    * def datos = read('file:target/datos.json')
    * def telefonoEmisor = datos.telefonoEmisor
    * def idReceptor = datos.idReceptor
    * def saldoEmisorInicial = datos.saldoEmisorInicial
    * def cuerpoLoginEmisor = ({ phone: telefonoEmisor, pin: '123456' })
    Given url authUrl
    And path 'auth', 'v1', 'login'
    And header x-channel = 'POSTMAN'
    And request cuerpoLoginEmisor
    When method post
    Then status 200
    And match response.expiresIn == 3600
    * def tokenEmisor = response.token
    * def cuerpoTransferencia = ({ recipientId: idReceptor, amount: 450, description: 'Pago de Servicios' })
    Given url transactionUrl
    And path 'transaction', 'v1', 'transfer'
    And header x-channel = 'POSTMAN'
    And header Authorization = 'Bearer ' + tokenEmisor
    And request cuerpoTransferencia
    When method post
    Then status 200
    And match response.status == 'COMPLETED'
    And match response.transactionId == '#string'
    And match response.referenceCode == '#string'
    * def codigoTransaccion = response.referenceCode
    * set datos.codigoTransaccion = codigoTransaccion
    * karate.write(datos, 'datos.json')
    Given url walletUrl
    And path 'wallet', 'v1', 'balance'
    And header x-channel = 'POSTMAN'
    And header Authorization = 'Bearer ' + tokenEmisor
    When method get
    Then status 200
    * def saldoEmisorFinal = response.balance
    * def esperadoEmisor = saldoEmisorInicial - 450
    And match saldoEmisorFinal == esperadoEmisor
    And assert saldoEmisorFinal < saldoEmisorInicial

  Scenario: Escenario 3 - Validacion de la transferencia en el Receptor
    * def datos = read('file:target/datos.json')
    * def telefonoEmisor = datos.telefonoEmisor
    * def telefonoReceptor = datos.telefonoReceptor
    * def saldoReceptorInicial = datos.saldoReceptorInicial
    * def codigoTransaccion = datos.codigoTransaccion
    * def cuerpoLoginReceptor = ({ phone: telefonoReceptor, pin: '123456' })
    Given url authUrl
    And path 'auth', 'v1', 'login'
    And header x-channel = 'POSTMAN'
    And request cuerpoLoginReceptor
    When method post
    Then status 200
    And match response.expiresIn == 3600
    * def tokenReceptor = response.token
    Given url walletUrl
    And path 'wallet', 'v1', 'balance'
    And header x-channel = 'POSTMAN'
    And header Authorization = 'Bearer ' + tokenReceptor
    When method get
    Then status 200
    * def saldoReceptorFinal = response.balance
    * def esperadoReceptor = saldoReceptorInicial + 450
    And match saldoReceptorFinal == esperadoReceptor
    And assert saldoReceptorFinal > saldoReceptorInicial
    Given url walletUrl
    And path 'wallet', 'v1', 'transactions'
    And header x-channel = 'POSTMAN'
    And header Authorization = 'Bearer ' + tokenReceptor
    When method get
    Then status 200
    And match response == '#array'
    And assert response.length > 0
    And match response..referenceCode contains codigoTransaccion
    * def descripcionIngreso = 'De: ' + telefonoEmisor + '. Pago de Servicios'
    And match response..description contains descripcionIngreso

  Scenario: Escenario 4 - Flujo Administrador
    * def datos = read('file:target/datos.json')
    * def telefonoReceptor = datos.telefonoReceptor
    * def codigoTransaccion = datos.codigoTransaccion
    * def cuerpoAdmin = { username: 'admin', password: 'superpassword' }
    Given url adminUrl
    And path 'admin', 'v1', 'login'
    And header x-channel = 'ADMIN'
    And request cuerpoAdmin
    When method post
    Then status 200
    * def tokenAdmin = response.token
    Given url adminUrl
    And path 'admin', 'v1', 'transactions'
    And header x-channel = 'ADMIN'
    And header Authorization = 'Bearer ' + tokenAdmin
    When method get
    Then status 200
    And match response..referenceCode contains codigoTransaccion
    * def descripcionEgreso = 'Para: ' + telefonoReceptor + '. Pago de Servicios'
    And match response..description contains descripcionEgreso
