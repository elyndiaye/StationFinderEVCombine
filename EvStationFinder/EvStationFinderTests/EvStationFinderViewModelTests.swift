//
//  EvStationFinderTests.swift
//  EvStationFinderTests
//
//  Created by Ely Assumpcao Ndiaye on 05/07/25.
//

import XCTest
import Combine
@testable import EvStationFinder

class NetworkServiceSpy: NetworkServiceProtocol {
    var resultToReturn: Result<[EvStation], ApiError> = .success([])

       func fetchStationList(zipCode: String) -> AnyPublisher<[EvStation], ApiError> {
           return resultToReturn.publisher.eraseToAnyPublisher()
       }
    
}

@MainActor
final class HomeViewModelTests: XCTestCase {
    var viewModel: HomeViewModel!
        var service: NetworkServiceSpy!
        var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
           super.setUp()
           service = NetworkServiceSpy()
           viewModel = HomeViewModel(service: service)
       }

       override func tearDown() {
           viewModel = nil
           service = nil
           cancellables.removeAll()
           super.tearDown()
       }
    
    
    func testShowisEmpty_WhenZipCodeIsEmpty_ShouldShowsError()  {
        viewModel.zipCode = ""
        
         viewModel.loadStations()
        
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertEqual(viewModel.errorMessage, "Zip code is required")
    }
    
    func testShowIsInvalid_WhenZipCodeIsNotValid_ShouldShowsError()  {
        let mockService = NetworkServiceSpy()
        let viewModel = HomeViewModel(service: mockService)
        viewModel.zipCode = "0X0"
        
       viewModel.loadStations()
        
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertEqual(viewModel.errorMessage, "Zip code need to be valid.")
    }
    
    func testShowStations_WhenZipCodeIsValid_ShouldShowsStations()  {
        let mockService = NetworkServiceSpy()
        let viewModel = HomeViewModel(service: mockService)
        
        let stationMock: [EvStation] = [.init(id: 1, station_name: "Luxe Rodeo", street_address: "360 N Rodeo", city: "Beverly Hills", state: "CA", zip: "90210", latitude: 34.24831915271937, longitude: -118.44384765625)]
        
        mockService.resultToReturn = .success(stationMock)
        
        viewModel.zipCode = "10001"
        
        let expectation = self.expectation(description: "Stations loaded")
        
        viewModel.$stations.dropFirst()
            .sink{ stations in
                XCTAssertEqual(stations.count, 1)
                XCTAssertEqual(stations.first?.station_name, "Luxe Rodeo")
                expectation.fulfill()
            }.store(in: &cancellables)
        
        viewModel.loadStations()

            wait(for: [expectation], timeout: 1)
    }
    
    func testError_WhenFetchingStationsFails_ShouldShowsError()  {
        
        viewModel.zipCode = "10001"
        service.resultToReturn = .failure(.badRequest)
        
        let expectation = self.expectation(description: "Show error")
        
        viewModel.$showAlert
            .dropFirst()
            .sink{ showAlert in
            if showAlert {
                            XCTAssertEqual(self.viewModel.errorMessage, "Station not found")
                            expectation.fulfill()
                        }
        }.store(in: &cancellables)
        
         viewModel.loadStations()
        wait(for: [expectation], timeout: 1)

    }
    
}
