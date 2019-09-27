# EbsSDK

[![CI Status](https://img.shields.io/travis/sergey.rybchinsky@waveaccess.ru/EbsSDK.svg?style=flat)](https://travis-ci.org/sergey.rybchinsky@waveaccess.ru/EbsSDK)
[![Version](https://img.shields.io/cocoapods/v/EbsSDK.svg?style=flat)](https://cocoapods.org/pods/EbsSDK)
[![License](https://img.shields.io/cocoapods/l/EbsSDK.svg?style=flat)](https://cocoapods.org/pods/EbsSDK)
[![Platform](https://img.shields.io/cocoapods/p/EbsSDK.svg?style=flat)](https://cocoapods.org/pods/EbsSDK)

SDK ЕБС обеспечивает:
1.	Проверку наличия мобильного приложения для идентификации (МП ЕБС).
2.	Формирование запроса на прохождение биометрической верификации в ЕБС.
3.	Взаимодействие пользовательского приложения, авторизации в ЕСИА и МП ЕБС для биометрической верификации.

## Installation

EbsSDK is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
source 'https://github.com/EBSBIO/EBSSDK'

...

pod 'EbsSDK', '~> 1.0.0'
```

## Author

sergey.rybchinsky@waveaccess.ru, sergey.rybchinsky@waveaccess.ru

## License

EbsSDK is available under the MIT license. See the LICENSE file for more info.

## Usage
1. Добавьте в info.plist в LSApplicationQueriesSchemes ключ ebs
2. Добавьте в URL Types URL схему с названием вашего приложения
3. в методе requestAuthorization в параметр urlScheme внесите указанное в п.2 название приложение
4. в AppDelegate добавьте метод  application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool и в него добавьте метод sdk process(openUrl: URL, from sourceApplication: String), пример: EbsSDKClient.shared.process(openUrl: url, from: options[UIApplicationOpenURLOptionsKey.sourceApplication])

## Integration

Допускается установка фреймворка без менеджера зависимостей. Подробнее: https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPFrameworks/Tasks/CreatingFrameworks.html#//apple_ref/doc/uid/20002258-106880
В AppDelegate необходимо импортировать библиотеку EbsSDK:

Также в файле AppDelegate необходимо реализовать метод:
```ruby

import EbsSDK
...
func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOp-tionsKey: Any] = [:]) -> Bool {
   EbsSDKClient.shared.process(openUrl: url, from: op-tions[UIApplicationOpenURLOptionsKey.sourceApplication] as! String)
   return true
}
```

## Dependencies

Приложение не использует дополнительные библиотеки для своей работы.
Для разрабатываемого приложения должен быть зарегистрирована URL-Scheme для возможности перехода в приложение с приложения МП ЕБС https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html.
Для разрабатываемого приложения должен быть добавлен ключ в info.plist в LSApplicationQueriesSchemes с значением ebs.

## Introduction
# Общее описание библиотеки

Для авторизации в единой биометрической системе SDK предоставляет класс
EbsSDKClient.

В первую очередь вызывает метод  set(scheme: _ ), который конфигурирует SDK для работы с данным банковским приложением.
Затем после получения Location приложением банка вызывается метод requestEsiaSession(urlString: _ ) куда передается Location.
При вызове этого метода, SDK проверяет наличие установленного на устройстве мо-бильного приложения ЕБС. В случае его отсутствия выводится диалоговое окно с запросом на установку МП ЕБС. При положительном ответе пользователя  открывается окно прило-жения ЕБС, если приложение отсутствует, то открывается приложение App Store с предло-жением установить МП ЕБС .
Если приложение ЕБС установлено на устройстве, то после вызова requestAuthorization в  МП ЕБС производится авторизация пользователя в ЕСИА посред-ством логина/пароля.
После успешной авторизации в ЕСИА, результат ЕСИА авторизации передается в пользовательское приложение. МП ЕБС возвращает интент с результатом в пользователь-ское приложение, который обрабатывается в func application (_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
Ответ необходимо передать в handler. EbsSDKClient.shared.process(openUrl: url, from: options[UIApplicationOpenURLOptionsKey.sourceApplication]). Если авторизация прошла успешно, то SDK вернет State и Code. Используя их МП Банка должно получить SessionID для прохождения биоверификации пользователем. После успешного получения SessionID, вызывается метод requestAuthorization(sessionId: _ )
 МП ЕБС производит процедуру получения биометрических образцов, которые пе-редает в ЕБС на биометрическую верификацию пользователя. Результат биометрической верификации передается в пользовательское приложение.
МП ЕБС возвращает url с результатом в пользовательское приложение, который об-рабатывается в func application (_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
Ответ необходимо передать  в handler. EbsSDKClient.shared.process(openUrl: url, from: options[UIApplicationOpenURLOptionsKey.sourceApplication])
