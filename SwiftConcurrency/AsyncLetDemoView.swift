//
//  AsyncLetDemoView.swift
//  SwiftConcurrency
//
//  Created by JayHsia on 2023/10/21.
//

import SwiftUI

struct AsyncLetDemoView {
    @State private var isLoading = false
    @State private var user = User.empty
    @State private var timeMessage = " "
}

extension AsyncLetDemoView: View {
    var body: some View {
        VStack {
            Text(user.name)
                .font(.title.width(.standard))
            ZStack {
//                Image(uiImage: user.realImage ?? UIImage(imageLiteralResourceName: "avatarPlaceholder"))
//                    .resizable()
//                    .scaledToFit()
                Image(user.image)
                    .resizable()
                    .scaledToFit()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(2.0)
                }
            }
            Text(timeMessage)
            Button {
                Task {
                    if user.name == "匿名" {
                        isLoading = true
                        await fetch()
                        isLoading = false
                    } else {
                        user = User.empty
                        timeMessage = " "
                    }
                }
            } label: {
                Text(user.name == "匿名" ? "登入" : "登出")
                    .font(.title2)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    func fetch() async {
        let startTime = Date.now
        // 1
        user.name = await fetchUserName()
        user.image = await fetchImage()

        //2
//        async let name = fetchUserName()
//        async let image = fetchImage()
//        user.name = await name
//        user.image = await image
        //3
//        async let name = fetchUserName()
//        async let realImage = fetchRealImage()
//        user.name = await name
//        user.realImage = await realImage
        
        timeMessage = getElapsedTime(from: startTime)
    }
    
    func fetchUserName() async -> String {
        try! await Task.sleep(secounds: 1)
        return "Dog"
    }
    
    func fetchImage() async -> String {
        try! await Task.sleep(secounds: 1)
        return "Test1"
    }
    
    func fetchRealImageContinuation() async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            FetchImageManager.downloadImage { image, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let image = image else {
                    continuation.resume(throwing: APIError.noData)
                    return
                }
                continuation.resume(returning: image)
            }
        }
    }
    
    func fetchRealImage() async -> UIImage {
        return try! await FetchImageManager.downloadImage()
    }
}

struct AsyncLetDemoView_Previews: PreviewProvider {
    static var previews: some View {
        AsyncLetDemoView()
    }
}


class FetchImageManager {
    static let randomImageUrl = URL(string: "https://random.imagecdn.app/300/300")!
    static func downloadImage() async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(from: randomImageUrl)
        guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
            fatalError()
        }
        return UIImage(data: data)!
    }
    static func downloadImage(url: URL) async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
            fatalError()
        }
        return UIImage(data: data)!
    }
    
    static func downloadImage(completion: @escaping (UIImage?, Error?) -> Void) {
        URLSession.shared.dataTask(with: randomImageUrl) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                completion(image, nil)
            } else {
                completion(nil, APIError.noData)
            }
        }.resume()
    }
}
