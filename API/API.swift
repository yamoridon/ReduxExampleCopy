//
//  API.swift
//  API
//
//  Created by Kazuki Ohara on 2019/02/26.
//  Copyright © 2019 Kazuki Ohara. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import SwiftyBeaver
import GitHubAPI
import HTTPStatusCodes

let logger = SwiftyBeaver.self

public struct Response<T: Codable> {
    public let content: T
    public let urlRequest: URLRequest
}

public struct NoContent: Codable {}

// MARK: - For AccessToken
public typealias AccessToken = String
extension RequestBuilder where T: Decodable {
    fileprivate func addAuthorizationHeader(_ accessToken: AccessToken) {
        _ = self.addHeader(name: "Authorization", value: "token \(accessToken)")
    }
}

// MARK: - Logger
private func loggerInfo(_ urlRequest: URLRequest) {
    #if DEBUG
    logger.info("\n⚡️ \(urlRequest.cURLString) | jq .")
    #endif
}

private func loggerError(_ urlRequest: URLRequest, error: Error) {
    #if DEBUG
    logger.error("\(error)\n🚫 \(urlRequest.cURLString) | jq .")
    #endif
}

// MARK: - Privitive Helper Methods

// MARK: - Single<T>
public func requestAsSingle<T: Decodable>(requestBuilder rb: RequestBuilder<T>) -> Single<Response<T>> {
    return RxSwift.Single.create { observer -> Disposable in
        guard let rb = rb as? AlamofireRequestBuilder<T>, let urlRequest = rb.makeDataRequest().request else {
            observer(.error(APIDomainError.unreachable))
            return Disposables.create()
        }

        loggerInfo(urlRequest)
        rb.execute { response, error in
            if let error = error {
                loggerError(urlRequest, error: error)
                if let responseError = (error as? GitHubAPI.ErrorResponse)?.responseError {
                    if let networkError = responseError.networkError {
                        observer(.error(APIDomainError.network(error: networkError)))
                    } else {
                        observer(.error(APIDomainError.response(error: responseError)))
                    }
                } else {
                    observer(.error(APIDomainError.unknownError(error: error)))
                }
            } else if let body = response?.body {
                let response = Response(content: body, urlRequest: urlRequest)
                observer(.success(response))
            } else {
                observer(.error(APIDomainError.unreachable))
            }
        }
        return Disposables.create()
    }
}

// MARK: - Single<NoContent>
private func requestAsSingleNoConent(requestBuilder rb: RequestBuilder<Void>) -> Single<Response<NoContent>> {
    return RxSwift.Single.create { observer -> Disposable in
        guard let rb = rb as? AlamofireRequestBuilder<Void>, let urlRequest = rb.makeDataRequest().request else {
            observer(.error(APIDomainError.unreachable))
            return Disposables.create()
        }

        loggerInfo(urlRequest)
        rb.execute { response, error in
            if let error = error {
                loggerError(urlRequest, error: error)
                if let responseError = (error as? GitHubAPI.ErrorResponse)?.responseError {
                    if let networkError = responseError.networkError {
                        observer(.error(APIDomainError.network(error: networkError)))
                    } else {
                        observer(.error(APIDomainError.response(error: responseError)))
                    }
                } else {
                    observer(.error(APIDomainError.unknownError(error: error)))
                }
            } else if let response = response, response.statusCode == HTTPStatusCode.noContent.rawValue {
                // For 204 NoContent
                let response = Response(content: NoContent(), urlRequest: urlRequest)
                observer(.success(response))
            } else {
                observer(.error(APIDomainError.unreachable))
            }
        }
        return Disposables.create()
    }
}

// MARK: - GitHubAPI.DefaultAPI
extension GitHubAPI.DefaultAPI {
    public class func publicReposGetSingle(perPage: Int) -> Single<Response<[GitHubAPI.PublicRepo]>> {
        let rb = repositoriesGetWithRequestBuilder(perPage: perPage)
        return requestAsSingle(requestBuilder: rb)
    }

    public class func userReposGetSingle(accessToken: AccessToken) -> Single<Response<[GitHubAPI.Repo]>> {
        let rb = userReposGetWithRequestBuilder()
        rb.addAuthorizationHeader(accessToken)
        return requestAsSingle(requestBuilder: rb)
    }

    public class func reposOwnerRepoGetSingle(owner: String, repo: String) -> Single<Response<GitHubAPI.Repo>> {
        let rb = reposOwnerRepoGetWithRequestBuilder(owner: owner, repo: repo)
        return requestAsSingle(requestBuilder: rb)
    }

    public class func reposOwnerRepoAuthenticatedGetSingle(accessToken: AccessToken, owner: String, repo: String) -> Single<Response<GitHubAPI.Repo>> {
        let rb = reposOwnerRepoGetWithRequestBuilder(owner: owner, repo: repo)
        rb.addAuthorizationHeader(accessToken)
        return requestAsSingle(requestBuilder: rb)
    }

    public class func userGetSingle(accessToken: AccessToken) -> Single<Response<User>> {
        let rb = userGetWithRequestBuilder()
        rb.addAuthorizationHeader(accessToken)
        return requestAsSingle(requestBuilder: rb)
    }

    public class func publicUserGetsingle(username: String) -> Single<Response<PublicUser>> {
        let rb = usersUsernameGetWithRequestBuilder(username: username)
        return requestAsSingle(requestBuilder: rb)
    }

    public class func reposeOwnerRepoReadmeGetsingle(accessToken: AccessToken?, owner: String, repo: String) -> Single<Response<GitHubAPI.Readme>> {
        let rb = reposOwnerRepoReadmeGetWithRequestBuilder(owner: owner, repo: repo)
        if let accessToken = accessToken {
            rb.addAuthorizationHeader(accessToken)
        }
        return requestAsSingle(requestBuilder: rb)
    }

}
