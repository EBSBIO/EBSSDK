//
//  EbsSdk.swift
//  EbsSDK
//
//  Created by Vitalii Poponov on 17.04.2018.
//  Copyright © 2018 Vitalii Poponov. All rights reserved.
//

import Foundation

extension EbsSDKClient {

	/// EBS verification completion handler
	public typealias AuthorizationCompletion = (AuthorizationRequestResult) -> Void

	/// Esia authentication completion handler
	public typealias EsiaCompletion = (EsiaRequestResult) -> Void

	/// Enum describes EBS Verification errors
	public enum AuthorizationError {
		case ebsNotInstalled
		case identificationFailed
		case sdkIsNotConfigured
		case unknown
	}

	/// Enum describes ESIA authentication result
	public enum EsiaRequestResult {
		case success(esiaResult: EsiaToken)
		case failure
		case ebsNotInstalled
		case sdkIsNotConfigured
		case cancel
	}

	/// Enum describes EBS Verification result
	public enum AuthorizationRequestResult {
		case success(token: EbsToken)
		case failure(error: AuthorizationError)
		case cancel
	}
}

extension EbsSDKClient {

	private struct Constants {

		/// The EBS application identifier is retrieved using UIApplicationOpenURLOptionsKey.sourceApplication.
		static let ebsAppKey = "com.waveaccess.Ebs"

		/// Url to EBS's app store page
		static let appStoreUrl = "itms-apps://itunes.apple.com/app/id1436489633"

		/// EBS BundleURLSchemes
		static let ebsBundleURLSchemes = "ebs://"
	}

	/// Structure describes keys which are using in URL
	private struct EbsRequestKeys {

		/// Scheme mobile application of Credit organization
		static let applicationSchemeKey = "appScheme"

		/// Redirect URL for EBS.
		static let redirectUrlKey = "redirectUrl"

		/// Mobile application title of Credit organization
		static let titleKey = "title"

		/// EBS verification sessions identifier
		static let sessionIdKey = "sessionId"

		/// Information system about Mobile application of Credit organization
		static let infoSystemKey = "info_system"

		/// Cancel result identifier
		static let cancelKey = "cancel"
	}

	/// Text resources
	private struct Texts {
		static let ebsNotInstalledMessage = "Для авторизации необходимо установить приложение Единая биометрическая система"
		static let ebsNotInstalledCancelButtonTitle = "Отмена"
		static let ebsNotInstalledTitle = "Установить"
		static let ebsApplicationTitle = "Единая биометрическая система"
	}

	private enum State {
		case none
		case auth(completion: AuthorizationCompletion)
		case esia(completion: EsiaCompletion)
		case extendedAuth(completion: EsiaCompletion)
	}
}

public class EbsSDKClient {

	//MARK: - Public variables

	/// Shared instance of SDK client
	public static let shared = EbsSDKClient(application: Application())

	/// Describes ebs app is installed or not
	public var ebsAppIsInstalled: Bool {
		guard var urlComponents = URLComponents(string: Constants.ebsBundleURLSchemes) else {
			return false
		}

		let queryItems = [
			URLQueryItem(name: EbsRequestKeys.applicationSchemeKey, value: appUrlScheme),
			URLQueryItem(name: EbsRequestKeys.titleKey, value: self.appTitle),
			URLQueryItem(name: EbsRequestKeys.infoSystemKey, value: infoSystem)]

		urlComponents.queryItems = queryItems

		if let url = urlComponents.url, application.canOpenURL(url) {
			return true
		}
		else {
			return false
		}
	}

	//MARK: - Private variables

	private let application: UIApplicationProtocol
	private var appUrlScheme: String?
	private var appTitle: String?
	private var infoSystem: String?
	private var presentingController: UIViewController?
	private var authEsiaState: State = .none

	// MARK: Inits

	//TODO: Make it public for unit tests only
	private init(application: UIApplicationProtocol) {
		self.application = application
	}

	//MARK: - Public

	/// Сonfigures SDK for specific app
	///  - Parameter appUrlScheme: Url scheme of the app
	///  - Parameter appTitle: Name of the app
	///  - Parameter infoSystem: System information about the app
	///  - Parameter presenting: Current view controller. Needs for show alert when ebs is not installed
	public func set(scheme: String, title: String, infoSystem: String, presenting controller: UIViewController?) {
		self.appUrlScheme = scheme
		self.appTitle = title
		self.infoSystem = infoSystem
		self.presentingController = controller
	}

	/// Creates ESIA session and returns esia code and state after ESIA authentication
	///  - Parameter urlString: ESIA authentication url
	///  - Parameter completion: Completion handler
	public func requestEsiaSession(urlString: String, completion: @escaping EsiaCompletion) {
		authEsiaState = .esia(completion: completion)
		openUrlIfNeeded(locationUrl: urlString)
	}

	/// Requests EBS verification and returns EBS verification token
	///  - Parameter sessionId: EBS session identifier
	///  - Parameter completion: Completion handler
	public func requestAuthorization(sessionId: String, completion: @escaping AuthorizationCompletion) {
		authEsiaState = .auth(completion: completion)
		openUrlIfNeeded(sessionId: sessionId)
	}

	/// Requests ESIA authentication for receiving access to extended verification result
	///  - Parameter sessionId: ESIA authentication url
	///  - Parameter completion: Completion handler
	public func requestExtendedAuthorization(location: String, completion: @escaping EsiaCompletion) {
		authEsiaState = .extendedAuth(completion: completion)
		openUrlIfNeeded(locationUrl: location)
	}

	/// Processes url with receive from EBS. Should be invoked in AppDelegate.application(_ app:, open:, options:)
	///  - Parameter openUrl: The URL resource to open
	///  - Parameter sourceApplication: A dictionary of URL handling options
	public func process(openUrl: URL, from sourceApplication: String) {
		guard sourceApplication == Constants.ebsAppKey else {
			return
		}

		switch authEsiaState {
		case .auth(let completion):
			guard let urlComponents = URLComponents(string: openUrl.absoluteString), let queryItems = urlComponents.queryItems else {
				completion(.failure(error: .unknown))
				return
			}

			if
					let verifyToken = getValue(from: queryItems, for: EbsToken.CodingKeys.verifyToken),
					let expired = getValue(from: queryItems, for: EbsToken.CodingKeys.expired) {
				let token = EbsToken(verifyToken: verifyToken, expired: expired)
				completion(.success(token: token))
				return
			}

			if getValue(from: queryItems, for: EbsRequestKeys.cancelKey) != nil {
				completion(.cancel)
				return
			}

			completion(.failure(error: .identificationFailed))
		case .esia(let completion), .extendedAuth(let completion):
			guard let urlComponents = URLComponents(string: openUrl.absoluteString), let queryItems = urlComponents.queryItems else {
				completion(.failure)
				return
			}

			if let state = getValue(from: queryItems, for: EsiaToken.CodingKeys.state),
					let code = getValue(from: queryItems, for: EsiaToken.CodingKeys.code) {
				let esiaResult = EsiaToken(code: code, state: state)
				completion(.success(esiaResult: esiaResult))
				return
			}

			if getValue(from: queryItems, for: EbsRequestKeys.cancelKey) != nil {
				completion(.cancel)
				return
			}

			completion(.failure)
		case .none:
			break
		}
	}

	/// Opens EBS app in App store
	public func openEbsInAppStore() {
		guard  let url = URL(string: Constants.appStoreUrl) else { return }
		application.open(url)
	}

	private func openUrlIfNeeded(locationUrl: String? = nil, sessionId: String? = nil) {
		guard let appUrlScheme = self.appUrlScheme,
				var urlComponents = URLComponents(string: Constants.ebsBundleURLSchemes),
				let appTitle = appTitle,
				let infoSystem = infoSystem else {
			showSDKIsNotConfigured()
			return
		}

		let queryItems = [
			URLQueryItem(name: EbsRequestKeys.applicationSchemeKey, value: appUrlScheme),
			URLQueryItem(name: EbsRequestKeys.titleKey, value: appTitle),
			URLQueryItem(name: EbsRequestKeys.redirectUrlKey, value: locationUrl),
			URLQueryItem(name: EbsRequestKeys.sessionIdKey, value: sessionId),
			URLQueryItem(name: EbsRequestKeys.infoSystemKey, value: infoSystem)]

		urlComponents.queryItems = queryItems

		DispatchQueue.main.async {
			if let url = urlComponents.url, self.application.canOpenURL(url) {
				self.application.open(url)
			}
			else {
				self.showEbsNotInstalledAlert(authEsiaState: self.authEsiaState)
			}
		}
	}

	private func showSDKIsNotConfigured() {
		switch authEsiaState {
		case .auth(let completion):
			completion(.failure(error: .sdkIsNotConfigured))
		case .esia(let completion):
			completion(.sdkIsNotConfigured)
		default:
			break
		}
	}

	private func showEbsNotInstalledAlert(authEsiaState: State) {
		if let presentingController = presentingController {
			let alert = UIAlertController(title: Texts.ebsApplicationTitle, message: Texts.ebsNotInstalledMessage, preferredStyle: .alert)
			let cancel = UIAlertAction(title: Texts.ebsNotInstalledCancelButtonTitle, style: .cancel, handler: nil)
			alert.addAction(cancel)
			let install = UIAlertAction(title: Texts.ebsNotInstalledTitle, style: .default) { _ in
				if let url = URL(string: Constants.appStoreUrl) {
					self.application.open(url)
				}
			}
			alert.addAction(install)
			presentingController.present(alert, animated: true, completion: nil)
		}
		
		switch authEsiaState {
		case .auth(let completion):
			completion(.failure(error: .ebsNotInstalled))
		case .esia(let completion):
			completion(.ebsNotInstalled)
		default:
			break
		}
	}

	// MARK: Private URLQueryItem array parsing helpers

	private func getValue(from queryItems: [URLQueryItem], for key: EsiaToken.CodingKeys) -> String? {
		return getValue(from: queryItems, for: key.rawValue)
	}

	private func getValue(from queryItems: [URLQueryItem], for key: EbsToken.CodingKeys) -> String? {
		return getValue(from: queryItems, for: key.rawValue)
	}

	private func getValue(from queryItems: [URLQueryItem], for key: String) -> String? {
		return queryItems.first(where: { $0.name == key })?.value
	}
}
