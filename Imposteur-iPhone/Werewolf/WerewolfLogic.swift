import Foundation

enum WerewolfLogic {
    static func setupError(_ setup: WerewolfSetup) -> String? {
        if setup.playerCount < 4 || setup.playerCount > 30 {
            return "Choisis entre 4 et 30 joueurs."
        }
        if setup.roleCount != setup.playerCount {
            return "Il faut exactement autant de rôles que de joueurs."
        }
        if setup.count(.werewolf) < 1 {
            return "Ajoute au moins un Loup-Garou."
        }
        let nonWolves = setup.roleCount - setup.count(.werewolf)
        if nonWolves < 1 {
            return "Ajoute au moins un rôle du Village."
        }
        for role in WerewolfRole.allCases where !role.repeatable {
            if setup.count(role) > 1 {
                return "Le rôle \(role.title) est limité à un exemplaire."
            }
        }
        return nil
    }

    static func roles(from setup: WerewolfSetup) -> [WerewolfRole] {
        WerewolfRole.allCases.flatMap { role in
            Array(repeating: role, count: max(0, setup.count(role)))
        }
    }

    static func shuffled<T>(_ values: [T], randomIndex: (Int) -> Int = { Int.random(in: 0..<$0) }) -> [T] {
        var result = values
        guard result.count > 1 else { return result }
        for i in stride(from: result.count - 1, through: 1, by: -1) {
            let j = max(0, min(i, randomIndex(i + 1)))
            if i != j { result.swapAt(i, j) }
        }
        return result
    }

    static func assignPlayers(names: [String], setup: WerewolfSetup) -> [WerewolfPlayer] {
        let roleList = shuffled(roles(from: setup))
        return zip(names, roleList).map { WerewolfPlayer(name: $0.0, role: $0.1) }
    }

    static func nextNightStep(after current: WerewolfNightStep, nightNumber: Int, players: [WerewolfPlayer], hasLovers: Bool) -> WerewolfNightStep {
        func hasAlive(_ role: WerewolfRole) -> Bool {
            players.contains { $0.alive && $0.role == role }
        }

        var candidate: WerewolfNightStep
        switch current {
        case .villageSleeps:
            if nightNumber == 1 && hasAlive(.thief) { candidate = .thief }
            else if nightNumber == 1 && hasAlive(.cupid) { candidate = .cupid }
            else if nightNumber == 1 && hasLovers { candidate = .loversWake }
            else if hasAlive(.seer) { candidate = .seer }
            else if hasAlive(.werewolf) { candidate = .wolves }
            else if hasAlive(.witch) { candidate = .witch }
            else { candidate = .dawn }

        case .thief:
            if nightNumber == 1 && hasAlive(.cupid) { candidate = .cupid }
            else if nightNumber == 1 && hasLovers { candidate = .loversWake }
            else if hasAlive(.seer) { candidate = .seer }
            else if hasAlive(.werewolf) { candidate = .wolves }
            else if hasAlive(.witch) { candidate = .witch }
            else { candidate = .dawn }

        case .cupid:
            if nightNumber == 1 && hasLovers { candidate = .loversWake }
            else if hasAlive(.seer) { candidate = .seer }
            else if hasAlive(.werewolf) { candidate = .wolves }
            else if hasAlive(.witch) { candidate = .witch }
            else { candidate = .dawn }

        case .loversWake:
            if hasAlive(.seer) { candidate = .seer }
            else if hasAlive(.werewolf) { candidate = .wolves }
            else if hasAlive(.witch) { candidate = .witch }
            else { candidate = .dawn }

        case .seer:
            if hasAlive(.werewolf) { candidate = .wolves }
            else if hasAlive(.witch) { candidate = .witch }
            else { candidate = .dawn }

        case .wolves:
            candidate = hasAlive(.witch) ? .witch : .dawn

        case .witch:
            candidate = .dawn

        case .dawn:
            candidate = .dawn
        }
        return candidate
    }

    static func winner(players: [WerewolfPlayer]) -> WerewolfWinner? {
        let alive = players.filter(\.alive)
        guard !alive.isEmpty else { return .draw }

        if alive.count == 2,
           alive.allSatisfy(\.isLover),
           Set(alive.map { $0.role.camp }).count == 2 {
            return .lovers
        }

        let wolves = alive.filter { $0.role.camp == .wolves }.count
        let village = alive.count - wolves
        if wolves == 0 { return .village }
        if village == 0 { return .wolves }
        return nil
    }

    static func loverPartner(of playerID: UUID, players: [WerewolfPlayer]) -> WerewolfPlayer? {
        guard let player = players.first(where: { $0.id == playerID }), player.isLover else { return nil }
        return players.first { $0.id != playerID && $0.isLover }
    }
}
