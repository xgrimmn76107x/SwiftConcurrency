//
//  TaskGroupContentView.swift
//  SwiftConcurrency
//
//  Created by JayHsia on 2023/10/21.
//

import SwiftUI

enum APIError: Error {
    case noData
    case lossSomeData
}

class UserImageLoader: AsyncSequence, AsyncIteratorProtocol {
    typealias Element = User
    
    let userData: [UserData]
    var currentIndex = 0
    
    init(userData: [UserData], currentIndex: Int = 0) {
        self.userData = userData
        self.currentIndex = currentIndex
    }
    
    func makeAsyncIterator() -> UserImageLoader {
        return self
    }
    
    func next() async throws -> User? {
        guard currentIndex < userData.count else { return nil }
        guard let url = URL(string: userData[currentIndex ].imageUrl) else { return nil }
        defer { currentIndex += 1 }

        let realImage = try await FetchImageManager.downloadImage(url: url)
        return User(name: userData[currentIndex].name, realImage: realImage)
    }
}

class FetchUserManager {
    static func fetchUser(id: Int) async -> User {
        try! await Task.sleep(secounds: 1)
        let names = ["Test1", "Test2", "Test3", "Test4", "Test5"]
        return User(name: names[id - 1], image: "Test\(id)")
    }

    static func fetchUserThrows(id: Int) async throws -> User {
        try await Task.sleep(secounds: 1)
        if id == 3 {
            throw APIError.noData
        }
        let names = ["Test1", "Test2", "Test3", "Test4", "Test5"]
        return User(name: names[id - 1], image: "Test\(id)")
    }
    
    static func fetch(userDatas: [UserData]) async -> [User] {
        await withTaskGroup(of: User.self, returning: [User].self) { group in
            for data in userDatas {
                group.addTask {
                    let realImage = try? await FetchImageManager.downloadImage(url: URL(string: data.imageUrl)!)
                    return User(name: data.name, realImage: realImage)
                }
            }
            var users = [User]()
            for await result in group {
                users.append(result)
            }
            return users
        }
        // sequential
//        await withTaskGroup(of: (user: User, seq: Int).self, returning: [User].self) { group in
//            for data in userDatas {
//                group.addTask {
//                    let realImage = try? await FetchImageManager.downloadImage(url: URL(string: data.imageUrl)!)
//                    return (User(name: data.name, realImage: realImage), data.seq)
//                }
//            }
//            var users = Array(repeating: User?.none, count: userDatas.count)
//            for await result in group {
//                users[result.seq - 1] = result.user
//            }
//            return users.compactMap { $0 }
//        }
    }
    
    static func fetch(userIDs: [Int]) async -> [User] {
        await withTaskGroup(of: User.self, returning: [User].self) { group in
            for id in userIDs {
                group.addTask {
                    await fetchUser(id: id)
                }
            }
            var users = [User]()
            for await result in group {
                users.append(result)
            }
            return users
        }
        // sequential
//        await withTaskGroup(of: (index: Int, user: User).self, returning: [User].self) { group in
//            for id in userIDs {
//                group.addTask {
//                    (id-1, await fetchUser(id: id))
//                }
//            }
//            var users = Array(repeating: User?.none, count: userIDs.count)
//            for await result in group {
//                users[result.index] = result.user
//            }
//            return users.compactMap { $0 }
//        }
    }

    @Sendable static func fetchThrows(userIDs: [Int]) async throws -> [User] {
        try await withThrowingTaskGroup(of: (index: Int, user: User?).self, returning: [User].self) { group in
            for id in userIDs {
                group.addTask {
                    (id-1, try await fetchUserThrows(id: id))
                }
            }
            var users = Array(repeating: User?.none, count: userIDs.count)
            for try await result in group {
                users[result.index] = result.user
            }
            
            return users.compactMap { $0 }
        }
    }
}

struct UserData {
    var name: String
    var imageUrl: String
    var seq: Int
}

struct User {
    var name: String
    var image: String = ""
    var realImage: UIImage?
    
    static let empty = User(name: "匿名", image: "avatarPlaceholder")
}

struct ContentView {
    @State private var isLoading = false
    @State private var users = [User]()
    @State private var timeMessage = "下載中"
    
    
//    func fetchUser(id: Int) async -> User {
//        try! await Task.sleep(secounds: 1)
//        let names = ["Test1", "Test2", "Test3", "Test4", "Test5"]
//        return User(name: names[id - 1], image: "Test\(id)")
//    }
//
//    @Sendable func fetch() async {
//        let startTime = Date.now
//        let userIDs = Array(1...5)
//
//        await withTaskGroup(of: Void.self) { group in
//            for id in userIDs {
//                group.addTask {
//                    users.append(await fetchUser(id: id))
//                }
//            }
//        }
//        timeMessage = getElapsedTime(from: startTime)
//    }
}

extension ContentView: View {
    var body: some View {
        NavigationView {
            ZStack {
                List($users.indices, id: \.self) { index in
                    let user = users[index]
                    HStack {
                        Image(uiImage: user.realImage ?? UIImage(imageLiteralResourceName: "avatarPlaceholder"))
//                        Image(user.image)
                            .resizable().aspectRatio(contentMode: .fill).clipShape(Circle())
                            .frame(width: 120, height: 120)
                            .padding()
                        Text(user.name)
                            .font(.title2.width(.standard))
                    }
                }
                .navigationTitle(timeMessage)
                .navigationBarTitleDisplayMode(.inline)
                .refreshable(action: reload)
                if isLoading {
                    ProgressView()
                        .scaleEffect(2.0)
                }
            }
        }
        .task(fetch)
    }
    
    @Sendable func fetch() async {
        isLoading = true
        let startTime = Date.now
        let userIDs = Array(1...5)
        let userDatas: [UserData] = [
            UserData(name: "Test1", imageUrl: "https://upload-images.jianshu.io/upload_images/5809200-a99419bb94924e6d.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240", seq: 1),
            UserData(name: "Test2", imageUrl: "https://upload-images.jianshu.io/upload_images/5809200-736bc3917fe92142.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240", seq: 2),
            UserData(name: "Test3", imageUrl: "https://upload-images.jianshu.io/upload_images/5809200-7fe8c323e533f656.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240", seq: 3),
            UserData(name: "Test4", imageUrl: "https://upload-images.jianshu.io/upload_images/5809200-c12521fbde6c705b.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240", seq: 4),
            UserData(name: "Test5", imageUrl: "https://upload-images.jianshu.io/upload_images/5809200-caf66b935fd00e18.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240", seq: 5)
        ]
        // 1
//        users = await FetchUserManager.fetch(userIDs: userIDs)
//        timeMessage = getElapsedTime(from: startTime)
        // 1
        // 2
//        do {
//            users = try await FetchUserManager.fetchThrows(userIDs: userIDs)
//            timeMessage = getElapsedTime(from: startTime)
//        } catch {
//            timeMessage = "發生錯誤 \(error)"
//        }
        // 2
        // Real image url
        // 1
//        users = await FetchUserManager.fetch(userDatas: userDatas)
//        timeMessage = getElapsedTime(from: startTime)
        // 2
        let imageLoader = UserImageLoader(userData: userDatas)
        do {
            for try await user in imageLoader {
//                if user.name == "Test3" {
//                    imageLoader.currentIndex += 1
//                }
                users.append(user)
            }
            timeMessage = getElapsedTime(from: startTime)
        } catch {
            timeMessage = "發生錯誤 \(error)"
        }
        // 2
        isLoading = false
    }
    
    @Sendable func reload() async {
        users = []
        timeMessage = "重新下載中"
        await fetch()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

func getElapsedTime(from startTime: Date) -> String {
    let currentTime = Date()
    let elapsedTime = currentTime.timeIntervalSince(startTime)
    return "完成時間經過: \(elapsedTime)"
}
