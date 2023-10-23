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
    
    @Sendable static func fetch(userIDs: [Int]) async -> [User] {
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


struct User {
    var name: String
    var image: String
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
                        Image(user.image)
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
        // 1
//        users = await FetchUserManager.fetch(userIDs: userIDs)
//        timeMessage = getElapsedTime(from: startTime)
        // 1
        // 2
        do {
            users = try await FetchUserManager.fetchThrows(userIDs: userIDs)
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
