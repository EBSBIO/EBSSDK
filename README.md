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
pod 'EbsSDK', '~> 1.0.3'
```

## Author

sergey.rybchinsky@waveaccess.ru

## License

EbsSDK is available under the MIT license. See the LICENSE file for more info.

## Usage
### Введение
SDK ЕБС обеспечивает:
1.	Проверку наличия мобильного приложения для идентификации (МП ЕБС).
2.	Формирование запроса на прохождение биометрической верификации в ЕБС.
3.	Взаимодействие пользовательского приложения, авторизации в ЕСИА и МП ЕБС для биометрической верификации.

### Общее описание библиотеки
ЕБС.SDK представляет собой файл EbsSDK.framework. 
Для авторизации в единой биометрической системе SDK предоставляет класс 
EbsSDKClient.

В первую очередь вызывает метод set(scheme: _), который конфигурирует SDK для работы с данным банковским приложением.
Затем после получения Location приложением банка вызывается метод requestEsia-Session(urlString: _) куда передается Location.
При вызове этого метода, SDK проверяет наличие установленного на устройстве мо-бильного приложения ЕБС. В случае его отсутствия выводится диалоговое окно с запросом на установку МП ЕБС. При положительном ответе пользователя  открывается окно прило-жения ЕБС, если приложение отсутствует, то открывается приложение App Store с предло-жением установить МП ЕБС .
Если приложение ЕБС установлено на устройстве, то после вызова requestAuthorization в  МП ЕБС производится авторизация пользователя в ЕСИА посред-ством логина/пароля.
После успешной авторизации в ЕСИА, результат ЕСИА авторизации передается в пользовательское приложение. МП ЕБС возвращает интент с результатом в пользователь-ское приложение, который обрабатывается в func application (_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool 
Ответ необходимо передать в handler. EbsSDKClient.shared.process(openUrl: URL, options: [UIApplication.OpenURLOptionsKey: Any]). Если авторизация прошла успешно, то SDK вернет State и Code. Используя их МП Банка должно получить SessionID для прохождения биоверификации пользователем. После успешного получения SessionID, вызывается метод requestAuthorization(sessionId: _) 

МП ЕБС производит процедуру получения биометрических образцов, которые пе-редает в ЕБС на биометрическую верификацию пользователя. Результат биометрической верификации передается в пользовательское приложение. 
МП ЕБС возвращает url с результатом в пользовательское приложение, который об-рабатывается в func application (_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool 
Ответ необходимо передать  в handler. EbsSDKClient.shared.process(openUrl: URL, options: [UIApplication.OpenURLOptionsKey: Any])

### Методы класса EbsSDKClient
#### set(scheme: String, title: String, infoSystem: String, presenting controller: UIViewController?)
Данный метод вызывается в самом начале и конфигурирует SDK. 

- scheme: URL-Schema, для которой МП-ЕБС вернет ответ приложению. Схема должны быть обязательно реализована в приложении
Подробнее: https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html

- title: Заголовок окна авторизации в ЕСИА.
Если title == nil, то заголовок окна используется по умолчанию
- infoSystem: Обязательный.
Инфо система банка. 
- presenting controller: Необязательный.
Передается объект UIViewController на котором происходит авторизация. Необходим для отображения алертов sdk.

#### requestEsiaSession(urlString: String, completion: @escaping EsiaCompletion)
Метод отправляет запрос на получение Esia токена 
- urlString: Обязательный. 
 Строка Location, которая была получена в результате выполнения запроса «mob/rs/back/ac/session»
- completion: Обязательный.
Блок обработки результата авторизации. Структура enum EsiaRequestResult содержит 3 кейса: 
    1.	success(esiaResult: EsiaToken). Содержит Есиа токен в случае успеш-ной авторизации
    code: String – код авторизации 
    state: String – состояние вызова.
    2.	failure. - авторизация прошла неуспешно
    3.	cancel - авторизация прервана пользователем
    4.	ebsNotInstalled – мп ЕБС не установлено
    5.	sdkIsNotConfigured – EbsSDK нескорфигурированно, необходимо вызвать метод set(scheme, title, infoSystem, presenting)
Результат метода:
Результат метода приходит в блок completion. В случае успеха параметр не содержит ошибку и содержит токен. В случае неудачи – параметр блока содержит ошибку с описани-ем и не содержит токена.

#### requestAuthorization(sessionId: String, completion: @escaping AuthorizationCompletion)
Метод вызывает запрос на получение токена ЕБС, путем прохождения биоверифика-ции.
- sessionId: Обязательный. 
Строка ID полученная в результате успешного выполнения запроса «mob/rs/back/session»
- completio: Обязательный.
    Блок обработки результата авторизации. Структура enum AuthorizationRe-questResult содержит 3 кейса: 
    1.	success(token: EbsToken). Содержит токен в случае успешной автори-зации
    a.	verifyToken: String – токен
    b.	expired: UInt64 – время жизни токена.
    2.	failure(error: AuthorizationError). Содержит токен в случае неудачной авторизации
    a.	ebsNotInstalled – приложение Ebs не установлено
    b.	identificationFailed - авторизация прошла неуспешно
    c.	unknown - другая ошибка 
    d.	sdkIsNotConfigured – EbsSDK нескорфигурированно, необхо-димо вызвать метод set(scheme, title, infoSystem, presenting)
    3.	cancel - авторизация прервана пользователем
Результат метода:
Результат метода приходит в блок completion. В случае успеха параметр не содержит ошибку и содержит токен. В случае неудачи – параметр блока содержит ошибку с описани-ем и не содержит токена. 

#### requestExtendedAuthorization(location: String, completion: @escaping EsiaCompletion)
Метод отправляет запрос на получение Esia токена для расширенной верификации

- urlString: Обязательный. 
 Строка Location, которая была получена в результате выполнения запроса «mob/rs/back/ac/(sessionId)/result»
- completion: Обязательный.
Блок обработки результата авторизации. Структура enum EsiaRequestResult содержит 3 кейса: 
    1.	success(esiaResult: EsiaToken). Содержит еста токен в случае успеш-ной авторизации
    a.	code: String – код авторизации 
    b.	state: String – состояние вызова.
    2.	failure. - авторизация прошла неуспешно
    3.	cancel - авторизация прервана пользователем
    4.	ebsNotInstalled – мп ЕБС не установлено
    5.	sdkIsNotConfigured – EbsSDK нескорфигурированно, необходимо вызвать метод set(scheme, title, infoSystem, presenting)
Результат метода:
Результат метода приходит в блок completion. В случае успеха параметр не содержит ошибку и содержит токен. В случае неудачи – параметр блока содержит ошибку с описани-ем и не содержит токена. 

#### process(openUrl: URL, options: [UIApplication.OpenURLOptionsKey: Any])
Метод обрабатывает открытие МП КО из МП ЕБС. Данный метод должен вызываться из AppDelegate в методе
optional func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool

#### openEbsInAppStore()
Метод позволяет открыть МП ЕБС страницу в App Store приложении.

#### ebsAppIsInstalled: Bool
Публичное свойство отображает установлено ли МП ЕБС на данном устройстве или нет.

### Зависимости
Приложение не использует дополнительные библиотеки для своей работы. 
Для разрабатываемого приложения должен быть зарегистрирована URL-Scheme для возможности перехода в приложение с приложения МП ЕБС https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html.
Для разрабатываемого приложения должен быть добавлен ключ в info.plist в LSApplicationQueriesSchemes с значением ebs.

### Интеграция
Допускается установка фреймворка без менеджера зависимостей. Подробнее: https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPFrameworks/Tasks/CreatingFrameworks.html#//apple_ref/doc/uid/20002258-106880
В AppDelegate необходимо импортировать библиотеку EbsSDK:
import EbsSDK

Также в файле AppDelegate необходимо реализовать метод 
```ruby
func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOp-tionsKey: Any] = [:]) -> Bool {
   EbsSDKClient.shared.process(openUrl: url, options: options)
   return true
}
```