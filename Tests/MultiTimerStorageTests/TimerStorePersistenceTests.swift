import XCTest
@testable import MultiTimerStorage
@testable import MultiTimerCore

final class TimerStorePersistenceTests: XCTestCase {
    private var tempDir: URL!
    private var store: TimerStore!

    override func setUp() async throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        store = try TimerStore(directory: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // TC-Persist-01: 保存 → 読み込みで内容が復元される
    func testTC_Persist_01_SaveAndLoad() async {
        let t = StoredTimer(id: "id-1", title: "作業", configuredMs: 1_500_000)
        await store.save(t)
        let loaded = await store.load()
        XCTAssertEqual(loaded, [t])
    }

    // TC-Persist-02: 同一 id 再保存で更新（重複しない）
    func testTC_Persist_02_SaveSameIdUpdates() async {
        let t1 = StoredTimer(id: "id-1", title: "Original", configuredMs: 60_000)
        let t2 = StoredTimer(id: "id-1", title: "Updated", configuredMs: 120_000)
        await store.save(t1)
        await store.save(t2)
        let loaded = await store.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].title, "Updated")
        XCTAssertEqual(loaded[0].configuredMs, 120_000)
    }

    // TC-Persist-03: 新規 id 保存で末尾追加
    func testTC_Persist_03_SaveNewIdAppends() async {
        let t1 = StoredTimer(id: "id-1", title: "First", configuredMs: 60_000)
        let t2 = StoredTimer(id: "id-2", title: "Second", configuredMs: 120_000)
        await store.save(t1)
        await store.save(t2)
        let loaded = await store.load()
        XCTAssertEqual(loaded, [t1, t2])
    }

    // TC-Persist-04: 削除 → 読み込みで対象が消える
    func testTC_Persist_04_DeleteRemovesTimer() async {
        let t1 = StoredTimer(id: "id-1", title: "First", configuredMs: 60_000)
        let t2 = StoredTimer(id: "id-2", title: "Second", configuredMs: 120_000)
        await store.save(t1)
        await store.save(t2)
        await store.delete(id: "id-1")
        let loaded = await store.load()
        XCTAssertEqual(loaded, [t2])
    }

    // TC-Persist-05: 存在しない id 削除で変化なし・エラーなし
    func testTC_Persist_05_DeleteNonExistentNoError() async {
        let t1 = StoredTimer(id: "id-1", title: "First", configuredMs: 60_000)
        await store.save(t1)
        await store.delete(id: "non-existent-id")
        let loaded = await store.load()
        XCTAssertEqual(loaded, [t1])
    }

    // TC-Persist-06: ファイル無し（初回）で空配列・エラーなし
    func testTC_Persist_06_LoadWhenNoFile() async {
        let loaded = await store.load()
        XCTAssertEqual(loaded, [])
    }

    // TC-Persist-07: 壊れた JSON → 空配列、かつ timer.corrupt-* が退避される
    func testTC_Persist_07_CorruptFileEvacuated() async throws {
        let fileURL = tempDir.appendingPathComponent("timer.json")
        try "not valid json {{{".data(using: .utf8)!.write(to: fileURL)
        let loaded = await store.load()
        XCTAssertEqual(loaded, [])
        let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        let corruptFiles = contents.filter { $0.lastPathComponent.hasPrefix("timer.corrupt-") }
        XCTAssertFalse(corruptFiles.isEmpty, "破損ファイルが退避されていない")
    }

    // TC-Persist-08: 13 件保存 → 12 件に切り詰め
    func testTC_Persist_08_Save13TruncatesTo12() async {
        for i in 1...13 {
            let t = StoredTimer(id: "id-\(i)", title: "Timer \(i)", configuredMs: i * 60_000)
            await store.save(t)
        }
        let loaded = await store.load()
        XCTAssertEqual(loaded.count, Constants.maxTimers)
    }

    // TC-Persist-09: 並行保存で直列化・ファイルが壊れない・最終状態が一貫する
    func testTC_Persist_09_ConcurrentSavesConsistent() async {
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    let t = StoredTimer(id: "id-\(i % 15)", title: "T\(i)", configuredMs: i * 1_000)
                    await self.store.save(t)
                }
            }
        }
        let loaded = await store.load()
        XCTAssertLessThanOrEqual(loaded.count, Constants.maxTimers, "12 件上限を超えてはならない")
        let ids = Set(loaded.map { $0.id })
        XCTAssertEqual(ids.count, loaded.count, "ID 重複があってはならない")
    }

    // TC-Persist-10: reorder 後に読み込むと新しい順で復元され、内容は変わらない
    func testTC_Persist_10_Reorder() async {
        let a = StoredTimer(id: "A", title: "a", configuredMs: 1_000)
        let b = StoredTimer(id: "B", title: "b", configuredMs: 2_000)
        let c = StoredTimer(id: "C", title: "c", configuredMs: 3_000)
        for t in [a, b, c] { await store.save(t) }
        await store.reorder(ids: ["C", "A", "B"])
        let loaded = await store.load()
        XCTAssertEqual(loaded, [c, a, b])
    }

    // TC-Persist-11: 同じ並び順で reorder してもファイルを書き換えない
    func testTC_Persist_11_ReorderSameOrderDoesNotWrite() async throws {
        for id in ["A", "B", "C"] { await store.save(StoredTimer(id: id, title: id, configuredMs: 0)) }
        let file = tempDir.appendingPathComponent("timer.json")
        let past = Date(timeIntervalSince1970: 1_000_000)
        try FileManager.default.setAttributes([.modificationDate: past], ofItemAtPath: file.path)
        await store.reorder(ids: ["A", "B", "C"])
        let mtime = try FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date
        XCTAssertEqual(mtime, past)
    }

    // TC-Persist-12: reorder の後に同一 id を再保存しても並び順を保つ
    func testTC_Persist_12_SaveAfterReorderKeepsOrder() async {
        for id in ["A", "B", "C"] { await store.save(StoredTimer(id: id, title: id, configuredMs: 0)) }
        await store.reorder(ids: ["C", "A", "B"])
        await store.save(StoredTimer(id: "A", title: "updated", configuredMs: 5_000))
        let loaded = await store.load()
        XCTAssertEqual(loaded.map(\.id), ["C", "A", "B"])
        XCTAssertEqual(loaded[1].title, "updated")
    }
}
