//
//  NetworkService.swift
//  EvStationFinder
//
//  Created by Ely Assumpcao Ndiaye on 05/07/25.
//

import Foundation
import Combine

protocol NetworkServiceProtocol {
    func fetchStationList(zipCode: String) -> AnyPublisher<[EvStation], ApiError>
}


class NetworkService: NetworkServiceProtocol {
    private let baseURL = "https://developer.nrel.gov/api/alt-fuel-stations/v1.json"
    private let apiKey = "0ZF8mMP7vb8zqFdaX38tJ7X9JDkCxRTZbMut7uSk"

    func fetchStationList(zipCode: String) -> AnyPublisher<[EvStation], ApiError>{
        
        var fullUrl = URLComponents(string: baseURL)
        fullUrl?.queryItems = [
                    URLQueryItem(name: "fuel_type", value: "ELEC"),
                    URLQueryItem(name: "zip", value: zipCode),
                    URLQueryItem(name: "api_key", value: apiKey)
                ]
 

        guard let url =  fullUrl?.url else {
            return Fail(error: ApiError.malformedRequest("URL inválida")).eraseToAnyPublisher()
        }
        

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return URLSession.shared.dataTaskPublisher(for: request).tryMap {
            result -> Data in
            
            guard let httpResponse = result.response as? HTTPURLResponse else {
                throw ApiError.unknown(nil)
            }
            
            switch httpResponse.statusCode {
                            case 200:
                                return result.data
                            case 400:
                                throw ApiError.badRequest
                            case 401:
                                throw ApiError.unauthorized
                            case 404:
                                throw ApiError.notFound
                            case 429:
                                throw ApiError.tooManyRequests
                            case 500...599:
                                throw ApiError.serverError
                            default:
                                throw ApiError.otherErrors
                            }
        }.decode(type: EvStationResponse.self, decoder: JSONDecoder())
            .map { $0.fuel_stations }
            .mapError { error in
                if let apiError = error as? ApiError {
                    return apiError
                } else if let decodingError = error as? DecodingError {
                    return ApiError.decodeError(decodingError)
                } else {
                    return ApiError.unknown(error)
                }
            } .eraseToAnyPublisher()
        
    }

}
