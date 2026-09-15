import ReminderCore

nonisolated extension ReminderList {
    static let samples: [ReminderList] = [
        Sample.household, Sample.personalTasks, Sample.work, Sample.hobby, Sample.other
    ]

    enum Sample {
        static let household = ReminderList(
            id: "00000000-0000-0000-0000-000000000101",
            title: "家事",
            isDefault: true,
            reminders: [
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000001",
                    title: "家計簿をつける",
                    dueDate: .init(date: "昨日", time: "7:38"),
                    priority: .medium,
                    notes: "サンプルメモ 01",
                    isCompleted: true,
                    creationDate: .init(date: "7日前", time: "8:12"),
                    lastModifiedDate: .init(date: "2日前", time: "12:12"),
                    completionDate: .init(date: "2日前", time: "12:12")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000011",
                    title: "エアコンのフィルターを掃除する",
                    dueDate: .init(date: "昨日", time: "12:42"),
                    priority: .medium,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "30日前", time: "10:32"),
                    lastModifiedDate: .init(date: "2日前", time: "14:32"),
                    completionDate: .init(date: "2日前", time: "14:32")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000013",
                    title: "自転車の空気を入れる",
                    dueDate: .init(date: "昨日", time: "14:04"),
                    priority: .medium,
                    notes: "サンプルメモ 13",
                    isCompleted: false,
                    creationDate: .init(date: "21日前", time: "8:27"),
                    lastModifiedDate: .init(date: "昨日", time: "12:27"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000014",
                    title: "お風呂を掃除する",
                    dueDate: .init(date: "昨日", time: "14:32"),
                    priority: .none,
                    notes: "サンプルメモ 14",
                    isCompleted: false,
                    creationDate: .init(date: "10日前", time: "8:57"),
                    lastModifiedDate: .init(date: "昨日", time: "12:57"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000015",
                    title: "服をたたむ",
                    dueDate: .init(date: "昨日", time: "15:10"),
                    priority: .low,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "3日前", time: "9:22"),
                    lastModifiedDate: .init(date: "今日", time: "13:22"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000017",
                    title: "車を洗う",
                    dueDate: .init(date: "昨日", time: "16:22"),
                    priority: .low,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "7日前", time: "9:52"),
                    lastModifiedDate: .init(date: "2日前", time: "13:52"),
                    completionDate: .init(date: "2日前", time: "13:52")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000019",
                    title: "車にガソリンを入れる",
                    dueDate: .init(date: "昨日", time: "17:33"),
                    priority: .none,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "1日前", time: "10:17"),
                    lastModifiedDate: .init(date: "昨日", time: "14:17"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000020",
                    title: "買い物リストを作る",
                    dueDate: .init(date: "昨日", time: "17:57"),
                    priority: .none,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "21日前", time: "10:47"),
                    lastModifiedDate: .init(date: "昨日", time: "14:47"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000039",
                    title: "Wi-Fiルーターを再起動する",
                    dueDate: .init(date: "今日", time: "18:06"),
                    priority: .medium,
                    notes: "サンプルメモ 39",
                    isCompleted: false,
                    creationDate: .init(date: "14日前", time: "8:54"),
                    lastModifiedDate: .init(date: "今日", time: "12:54"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000041",
                    title: "作り置きを準備する",
                    dueDate: .init(date: "明日", time: "8:07"),
                    priority: .medium,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "7日前", time: "9:16"),
                    lastModifiedDate: .init(date: "4日前", time: "13:16"),
                    completionDate: .init(date: "4日前", time: "13:16")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000043",
                    title: "粗大ゴミを申し込む",
                    dueDate: .init(date: "明日", time: "9:00"),
                    priority: .medium,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "14日前", time: "10:26"),
                    lastModifiedDate: .init(date: "今日", time: "14:26"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000044",
                    title: "ペットボトルを分別する",
                    dueDate: .init(date: "明日", time: "9:24"),
                    priority: .medium,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "10日前", time: "9:01"),
                    lastModifiedDate: .init(date: "昨日", time: "13:01"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000045",
                    title: "タオルを交換する",
                    dueDate: .init(date: "明日", time: "9:53"),
                    priority: .medium,
                    notes: "サンプルメモ 45",
                    isCompleted: false,
                    creationDate: .init(date: "3日前", time: "8:06"),
                    lastModifiedDate: .init(date: "今日", time: "12:06"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000046",
                    title: "クローゼットを整理する",
                    dueDate: .init(date: "明日", time: "10:19"),
                    priority: .high,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "30日前", time: "10:56"),
                    lastModifiedDate: .init(date: "4日前", time: "14:56"),
                    completionDate: .init(date: "4日前", time: "14:56")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000047",
                    title: "玄関の鍵を確認する",
                    dueDate: .init(date: "明日", time: "10:52"),
                    priority: .high,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "1日前", time: "10:41"),
                    lastModifiedDate: .init(date: "昨日", time: "14:41"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000049",
                    title: "トイレットペーパーを買う",
                    dueDate: .init(date: "明日", time: "12:08"),
                    priority: .low,
                    notes: "サンプルメモ 49",
                    isCompleted: false,
                    creationDate: .init(date: "5日前", time: "8:51"),
                    lastModifiedDate: .init(date: "昨日", time: "12:51"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000050",
                    title: "本棚を整理する",
                    dueDate: .init(date: "明日", time: "12:35"),
                    priority: .none,
                    notes: "サンプルメモ 50",
                    isCompleted: false,
                    creationDate: .init(date: "10日前", time: "8:21"),
                    lastModifiedDate: .init(date: "昨日", time: "12:21"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000051",
                    title: "コーヒー豆を買う",
                    dueDate: .init(date: "明日", time: "13:19"),
                    priority: .high,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "3日前", time: "10:26"),
                    lastModifiedDate: .init(date: "今日", time: "14:26"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000053",
                    title: "ベランダを掃除する",
                    dueDate: .init(date: "明日", time: "14:26"),
                    priority: .low,
                    notes: "サンプルメモ 53",
                    isCompleted: false,
                    creationDate: .init(date: "14日前", time: "8:06"),
                    lastModifiedDate: .init(date: "今日", time: "12:06"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000055",
                    title: "洗面台を掃除する",
                    dueDate: .init(date: "明日", time: "15:29"),
                    priority: .low,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "30日前", time: "9:16"),
                    lastModifiedDate: .init(date: "4日前", time: "13:16"),
                    completionDate: .init(date: "4日前", time: "13:16")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000056",
                    title: "お弁当のおかずを作る",
                    dueDate: .init(date: "明日", time: "16:10"),
                    priority: .high,
                    notes: "サンプルメモ 56",
                    isCompleted: false,
                    creationDate: .init(date: "21日前", time: "8:51"),
                    lastModifiedDate: .init(date: "昨日", time: "12:51"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000058",
                    title: "靴箱を掃除する",
                    dueDate: .init(date: "明日", time: "17:21"),
                    priority: .high,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "5日前", time: "9:31"),
                    lastModifiedDate: .init(date: "昨日", time: "13:31"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000059",
                    title: "段ボールをまとめる",
                    dueDate: .init(date: "明日", time: "17:50"),
                    priority: .medium,
                    notes: "サンプルメモ 59",
                    isCompleted: true,
                    creationDate: .init(date: "30日前", time: "8:36"),
                    lastModifiedDate: .init(date: "4日前", time: "12:36"),
                    completionDate: .init(date: "4日前", time: "12:36")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000060",
                    title: "キッチンの排水口を掃除する",
                    dueDate: .init(date: "明日", time: "18:17"),
                    priority: .high,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "10日前", time: "10:41"),
                    lastModifiedDate: .init(date: "昨日", time: "14:41"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000062",
                    title: "洗剤を補充する",
                    dueDate: .init(date: "2日後", time: "8:59"),
                    priority: .medium,
                    notes: "サンプルメモ 62",
                    isCompleted: false,
                    creationDate: .init(date: "5日前", time: "8:03"),
                    lastModifiedDate: .init(date: "昨日", time: "12:03"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000063",
                    title: "クリーニングを受け取る",
                    dueDate: .init(date: "2日後", time: "9:28"),
                    priority: .none,
                    notes: "サンプルメモ 63",
                    isCompleted: false,
                    creationDate: .init(date: "3日前", time: "8:18"),
                    lastModifiedDate: .init(date: "今日", time: "12:18"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000071",
                    title: "電池を買う",
                    dueDate: .init(date: "3日後", time: "9:16"),
                    priority: .medium,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "30日前", time: "9:28"),
                    lastModifiedDate: .init(date: "5日前", time: "13:28"),
                    completionDate: .init(date: "5日前", time: "13:28")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000079",
                    title: "シーツを洗う",
                    dueDate: .init(date: "4日後", time: "10:29"),
                    priority: .medium,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "14日前", time: "10:38"),
                    lastModifiedDate: .init(date: "今日", time: "14:38"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000080",
                    title: "宅配便を受け取る",
                    dueDate: .init(date: "4日後", time: "10:50"),
                    priority: .none,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "10日前", time: "10:53"),
                    lastModifiedDate: .init(date: "昨日", time: "14:53"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000081",
                    title: "牛乳を買う",
                    dueDate: .init(date: nil, time: nil),
                    priority: .medium,
                    notes: "サンプルメモ 81",
                    isCompleted: true,
                    creationDate: .init(date: "30日前", time: "8:00"),
                    lastModifiedDate: .init(date: "1日前", time: "12:00"),
                    completionDate: .init(date: "1日前", time: "12:00")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000082",
                    title: "卵を買う",
                    dueDate: .init(date: nil, time: nil),
                    priority: .none,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "5日前", time: "10:35"),
                    lastModifiedDate: .init(date: "昨日", time: "14:35"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000083",
                    title: "燃えるゴミを出す",
                    dueDate: .init(date: nil, time: nil),
                    priority: .none,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "14日前", time: "9:10"),
                    lastModifiedDate: .init(date: "今日", time: "13:10"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000084",
                    title: "洗濯物を干す",
                    dueDate: .init(date: nil, time: nil),
                    priority: .high,
                    notes: "サンプルメモ 84",
                    isCompleted: false,
                    creationDate: .init(date: "1日前", time: "8:45"),
                    lastModifiedDate: .init(date: "昨日", time: "12:45"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000085",
                    title: "リビングを掃除する",
                    dueDate: .init(date: nil, time: nil),
                    priority: .none,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "7日前", time: "10:20"),
                    lastModifiedDate: .init(date: "1日前", time: "14:20"),
                    completionDate: .init(date: "1日前", time: "14:20")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000093",
                    title: "水道料金を支払う",
                    dueDate: .init(date: nil, time: nil),
                    priority: .high,
                    notes: "サンプルメモ 93",
                    isCompleted: true,
                    creationDate: .init(date: "7日前", time: "8:00"),
                    lastModifiedDate: .init(date: "1日前", time: "12:00"),
                    completionDate: .init(date: "1日前", time: "12:00")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000094",
                    title: "電気料金を確認する",
                    dueDate: .init(date: nil, time: nil),
                    priority: .high,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "21日前", time: "10:35"),
                    lastModifiedDate: .init(date: "昨日", time: "14:35"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000097",
                    title: "観葉植物に水をあげる",
                    dueDate: .init(date: nil, time: nil),
                    priority: .high,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "30日前", time: "10:20"),
                    lastModifiedDate: .init(date: "1日前", time: "14:20"),
                    completionDate: .init(date: "1日前", time: "14:20")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000098",
                    title: "冷蔵庫を整理する",
                    dueDate: .init(date: nil, time: nil),
                    priority: .high,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "5日前", time: "9:55"),
                    lastModifiedDate: .init(date: "昨日", time: "13:55"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000099",
                    title: "夕食の準備をする",
                    dueDate: .init(date: nil, time: nil),
                    priority: .high,
                    notes: "サンプルメモ 99",
                    isCompleted: false,
                    creationDate: .init(date: "14日前", time: "8:30"),
                    lastModifiedDate: .init(date: "今日", time: "12:30"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000100",
                    title: "朝食用のパンを買う",
                    dueDate: .init(date: nil, time: nil),
                    priority: .low,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "1日前", time: "10:05"),
                    lastModifiedDate: .init(date: "昨日", time: "14:05"),
                    completionDate: nil
                ),
            ]
        )
        
        static let personalTasks = ReminderList(
            id: "00000000-0000-0000-0000-000000000102",
            title: "個人",
            isDefault: false,
            reminders: [
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000002",
                    title: "財布の中身を確認する",
                    dueDate: .init(date: "昨日", time: "8:00"),
                    priority: .none,
                    notes: "サンプルメモ 02",
                    isCompleted: true,
                    creationDate: .init(date: "30日前", time: "8:12"),
                    lastModifiedDate: .init(date: "2日前", time: "12:12"),
                    completionDate: .init(date: "2日前", time: "12:12")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000004",
                    title: "明日の服を準備する",
                    dueDate: .init(date: "昨日", time: "8:50"),
                    priority: .medium,
                    notes: "サンプルメモ 04",
                    isCompleted: false,
                    creationDate: .init(date: "14日前", time: "8:42"),
                    lastModifiedDate: .init(date: "今日", time: "12:42"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000006",
                    title: "寝る前にアラームを設定する",
                    dueDate: .init(date: "昨日", time: "9:49"),
                    priority: .high,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "5日前", time: "9:07"),
                    lastModifiedDate: .init(date: "昨日", time: "13:07"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000008",
                    title: "明日の予定を整理する",
                    dueDate: .init(date: "昨日", time: "11:02"),
                    priority: .low,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "10日前", time: "9:37"),
                    lastModifiedDate: .init(date: "昨日", time: "13:37"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000009",
                    title: "写真を整理する",
                    dueDate: .init(date: "昨日", time: "11:23"),
                    priority: .medium,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "14日前", time: "10:02"),
                    lastModifiedDate: .init(date: "今日", time: "14:02"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000010",
                    title: "カレンダーを確認する",
                    dueDate: .init(date: "昨日", time: "12:06"),
                    priority: .none,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "3日前", time: "10:02"),
                    lastModifiedDate: .init(date: "今日", time: "14:02"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000012",
                    title: "メモを整理する",
                    dueDate: .init(date: "昨日", time: "13:24"),
                    priority: .high,
                    notes: "サンプルメモ 12",
                    isCompleted: false,
                    creationDate: .init(date: "5日前", time: "8:27"),
                    lastModifiedDate: .init(date: "昨日", time: "12:27"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000021",
                    title: "ふるさと納税の書類を整理する",
                    dueDate: .init(date: "今日", time: "7:51"),
                    priority: .low,
                    notes: "サンプルメモ 21",
                    isCompleted: false,
                    creationDate: .init(date: "10日前", time: "8:09"),
                    lastModifiedDate: .init(date: "昨日", time: "12:09"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000024",
                    title: "健康診断を予約する",
                    dueDate: .init(date: "今日", time: "9:19"),
                    priority: .low,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "14日前", time: "10:14"),
                    lastModifiedDate: .init(date: "今日", time: "14:14"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000028",
                    title: "眼鏡を調整する",
                    dueDate: .init(date: "今日", time: "11:34"),
                    priority: .none,
                    notes: "サンプルメモ 28",
                    isCompleted: true,
                    creationDate: .init(date: "7日前", time: "8:24"),
                    lastModifiedDate: .init(date: "3日前", time: "12:24"),
                    completionDate: .init(date: "3日前", time: "12:24")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000031",
                    title: "クレジットカードの明細を確認する",
                    dueDate: .init(date: "今日", time: "13:05"),
                    priority: .high,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "3日前", time: "9:34"),
                    lastModifiedDate: .init(date: "今日", time: "13:34"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000034",
                    title: "美容院を予約する",
                    dueDate: .init(date: "今日", time: "14:42"),
                    priority: .high,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "1日前", time: "9:49"),
                    lastModifiedDate: .init(date: "昨日", time: "13:49"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000038",
                    title: "レンタル品を返却する",
                    dueDate: .init(date: "今日", time: "17:25"),
                    priority: .none,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "21日前", time: "10:59"),
                    lastModifiedDate: .init(date: "昨日", time: "14:59"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000048",
                    title: "履歴書を見直す",
                    dueDate: .init(date: "明日", time: "11:28"),
                    priority: .none,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "14日前", time: "9:46"),
                    lastModifiedDate: .init(date: "今日", time: "13:46"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000061",
                    title: "家族に電話する",
                    dueDate: .init(date: "2日後", time: "8:19"),
                    priority: .low,
                    notes: "サンプルメモ 61",
                    isCompleted: false,
                    creationDate: .init(date: "21日前", time: "8:03"),
                    lastModifiedDate: .init(date: "昨日", time: "12:03"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000064",
                    title: "日記を書く",
                    dueDate: .init(date: "2日後", time: "10:12"),
                    priority: .medium,
                    notes: "サンプルメモ 64",
                    isCompleted: false,
                    creationDate: .init(date: "1日前", time: "8:33"),
                    lastModifiedDate: .init(date: "昨日", time: "12:33"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000065",
                    title: "定期券を更新する",
                    dueDate: .init(date: "2日後", time: "10:44"),
                    priority: .none,
                    notes: "サンプルメモ 65",
                    isCompleted: false,
                    creationDate: .init(date: "10日前", time: "8:33"),
                    lastModifiedDate: .init(date: "昨日", time: "12:33"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000068",
                    title: "旅行の宿を予約する",
                    dueDate: .init(date: "3日後", time: "7:56"),
                    priority: .high,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "10日前", time: "9:13"),
                    lastModifiedDate: .init(date: "昨日", time: "13:13"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000069",
                    title: "役所の手続きを確認する",
                    dueDate: .init(date: "3日後", time: "8:21"),
                    priority: .low,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "1日前", time: "9:13"),
                    lastModifiedDate: .init(date: "昨日", time: "13:13"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000070",
                    title: "友人に連絡する",
                    dueDate: .init(date: "3日後", time: "8:48"),
                    priority: .low,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "7日前", time: "9:28"),
                    lastModifiedDate: .init(date: "5日前", time: "13:28"),
                    completionDate: .init(date: "5日前", time: "13:28")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000078",
                    title: "誕生日プレゼントを選ぶ",
                    dueDate: .init(date: "4日後", time: "9:54"),
                    priority: .low,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "3日前", time: "10:38"),
                    lastModifiedDate: .init(date: "今日", time: "14:38"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000086",
                    title: "メールに返信する",
                    dueDate: .init(date: nil, time: nil),
                    priority: .medium,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "21日前", time: "9:55"),
                    lastModifiedDate: .init(date: "昨日", time: "13:55"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000088",
                    title: "銀行に行く",
                    dueDate: .init(date: nil, time: nil),
                    priority: .medium,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "10日前", time: "10:05"),
                    lastModifiedDate: .init(date: "昨日", time: "14:05"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000089",
                    title: "郵便物を出す",
                    dueDate: .init(date: nil, time: nil),
                    priority: .none,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "30日前", time: "9:40"),
                    lastModifiedDate: .init(date: "1日前", time: "13:40"),
                    completionDate: .init(date: "1日前", time: "13:40")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000090",
                    title: "図書館に本を返す",
                    dueDate: .init(date: nil, time: nil),
                    priority: .low,
                    notes: "サンプルメモ 90",
                    isCompleted: false,
                    creationDate: .init(date: "5日前", time: "8:15"),
                    lastModifiedDate: .init(date: "昨日", time: "12:15"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000091",
                    title: "歯医者を予約する",
                    dueDate: .init(date: nil, time: nil),
                    priority: .low,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "14日前", time: "10:50"),
                    lastModifiedDate: .init(date: "今日", time: "14:50"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000092",
                    title: "薬を受け取る",
                    dueDate: .init(date: nil, time: nil),
                    priority: .none,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "1日前", time: "9:25"),
                    lastModifiedDate: .init(date: "昨日", time: "13:25"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000095",
                    title: "保険証を更新する",
                    dueDate: .init(date: nil, time: nil),
                    priority: .low,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "3日前", time: "9:10"),
                    lastModifiedDate: .init(date: "今日", time: "13:10"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000096",
                    title: "靴を磨く",
                    dueDate: .init(date: nil, time: nil),
                    priority: .low,
                    notes: "サンプルメモ 96",
                    isCompleted: false,
                    creationDate: .init(date: "10日前", time: "8:45"),
                    lastModifiedDate: .init(date: "昨日", time: "12:45"),
                    completionDate: nil
                ),
            ]
        )
        
        static let work = ReminderList(
            id: "00000000-0000-0000-0000-000000000103",
            title: "仕事",
            isDefault: false,
            reminders: [
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000003",
                    title: "GitHubの通知を確認する",
                    dueDate: .init(date: "昨日", time: "8:21"),
                    priority: .high,
                    notes: "サンプルメモ 03",
                    isCompleted: false,
                    creationDate: .init(date: "3日前", time: "8:42"),
                    lastModifiedDate: .init(date: "今日", time: "12:42"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000005",
                    title: "コードをリファクタリングする",
                    dueDate: .init(date: "昨日", time: "9:11"),
                    priority: .high,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "21日前", time: "9:07"),
                    lastModifiedDate: .init(date: "昨日", time: "13:07"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000016",
                    title: "テストコードを書く",
                    dueDate: .init(date: "昨日", time: "15:55"),
                    priority: .low,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "30日前", time: "9:52"),
                    lastModifiedDate: .init(date: "2日前", time: "13:52"),
                    completionDate: .init(date: "2日前", time: "13:52")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000018",
                    title: "プルリクエストを確認する",
                    dueDate: .init(date: "昨日", time: "16:52"),
                    priority: .none,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "10日前", time: "10:17"),
                    lastModifiedDate: .init(date: "昨日", time: "14:17"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000033",
                    title: "マウスを掃除する",
                    dueDate: .init(date: "今日", time: "14:11"),
                    priority: .high,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "14日前", time: "9:34"),
                    lastModifiedDate: .init(date: "今日", time: "13:34"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000037",
                    title: "モニターを拭く",
                    dueDate: .init(date: "今日", time: "16:48"),
                    priority: .low,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "7日前", time: "10:44"),
                    lastModifiedDate: .init(date: "3日前", time: "14:44"),
                    completionDate: .init(date: "3日前", time: "14:44")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000040",
                    title: "デスク周りを片付ける",
                    dueDate: .init(date: "今日", time: "18:41"),
                    priority: .low,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "5日前", time: "10:59"),
                    lastModifiedDate: .init(date: "昨日", time: "14:59"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000042",
                    title: "次回の会議日程を調整する",
                    dueDate: .init(date: "明日", time: "8:32"),
                    priority: .none,
                    notes: "サンプルメモ 42",
                    isCompleted: false,
                    creationDate: .init(date: "1日前", time: "8:21"),
                    lastModifiedDate: .init(date: "昨日", time: "12:21"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000052",
                    title: "経費を精算する",
                    dueDate: .init(date: "明日", time: "13:59"),
                    priority: .medium,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "21日前", time: "9:31"),
                    lastModifiedDate: .init(date: "昨日", time: "13:31"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000054",
                    title: "ポートフォリオを更新する",
                    dueDate: .init(date: "明日", time: "14:49"),
                    priority: .medium,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "5日前", time: "10:11"),
                    lastModifiedDate: .init(date: "昨日", time: "14:11"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000057",
                    title: "議事録を共有する",
                    dueDate: .init(date: "明日", time: "16:38"),
                    priority: .none,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "7日前", time: "10:56"),
                    lastModifiedDate: .init(date: "4日前", time: "14:56"),
                    completionDate: .init(date: "4日前", time: "14:56")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000087",
                    title: "会議資料を確認する",
                    dueDate: .init(date: nil, time: nil),
                    priority: .low,
                    notes: "サンプルメモ 87",
                    isCompleted: false,
                    creationDate: .init(date: "3日前", time: "8:30"),
                    lastModifiedDate: .init(date: "今日", time: "12:30"),
                    completionDate: nil
                ),
            ]
        )
        
        static let hobby = ReminderList(
            id: "00000000-0000-0000-0000-000000000104",
            title: "趣味",
            isDefault: false,
            reminders: [
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000022",
                    title: "ストレッチをする",
                    dueDate: .init(date: "今日", time: "8:29"),
                    priority: .high,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "7日前", time: "9:04"),
                    lastModifiedDate: .init(date: "3日前", time: "13:04"),
                    completionDate: .init(date: "3日前", time: "13:04")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000026",
                    title: "小説を読む",
                    dueDate: .init(date: "今日", time: "10:29"),
                    priority: .none,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "3日前", time: "10:14"),
                    lastModifiedDate: .init(date: "今日", time: "14:14"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000029",
                    title: "筋トレをする",
                    dueDate: .init(date: "今日", time: "11:56"),
                    priority: .low,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "1日前", time: "10:29"),
                    lastModifiedDate: .init(date: "昨日", time: "14:29"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000030",
                    title: "Swiftを勉強する",
                    dueDate: .init(date: "今日", time: "12:30"),
                    priority: .none,
                    notes: "サンプルメモ 30",
                    isCompleted: true,
                    creationDate: .init(date: "30日前", time: "8:24"),
                    lastModifiedDate: .init(date: "3日前", time: "12:24"),
                    completionDate: .init(date: "3日前", time: "12:24")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000032",
                    title: "近所を散歩する",
                    dueDate: .init(date: "今日", time: "13:28"),
                    priority: .none,
                    notes: "サンプルメモ 32",
                    isCompleted: false,
                    creationDate: .init(date: "21日前", time: "8:39"),
                    lastModifiedDate: .init(date: "昨日", time: "12:39"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000036",
                    title: "英単語を覚える",
                    dueDate: .init(date: "今日", time: "16:03"),
                    priority: .low,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "10日前", time: "9:49"),
                    lastModifiedDate: .init(date: "昨日", time: "13:49"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000066",
                    title: "映画のチケットを予約する",
                    dueDate: .init(date: "2日後", time: "11:12"),
                    priority: .low,
                    notes: "サンプルメモ 66",
                    isCompleted: true,
                    creationDate: .init(date: "30日前", time: "8:48"),
                    lastModifiedDate: .init(date: "5日前", time: "12:48"),
                    completionDate: .init(date: "5日前", time: "12:48")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000072",
                    title: "語学アプリで学習する",
                    dueDate: .init(date: "3日後", time: "9:46"),
                    priority: .none,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "21日前", time: "9:43"),
                    lastModifiedDate: .init(date: "昨日", time: "13:43"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000073",
                    title: "ヨガをする",
                    dueDate: .init(date: "3日後", time: "10:30"),
                    priority: .medium,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "14日前", time: "9:58"),
                    lastModifiedDate: .init(date: "今日", time: "13:58"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000075",
                    title: "読書メモをまとめる",
                    dueDate: .init(date: "4日後", time: "8:12"),
                    priority: .low,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "7日前", time: "10:08"),
                    lastModifiedDate: .init(date: "5日前", time: "14:08"),
                    completionDate: .init(date: "5日前", time: "14:08")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000076",
                    title: "ランニングシューズを洗う",
                    dueDate: .init(date: "4日後", time: "8:54"),
                    priority: .high,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "5日前", time: "10:23"),
                    lastModifiedDate: .init(date: "昨日", time: "14:23"),
                    completionDate: nil
                ),
            ]
        )
        
        static let other = ReminderList(
            id: "00000000-0000-0000-0000-000000000105",
            title: "その他",
            isDefault: false,
            reminders: [
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000007",
                    title: "不要なファイルを削除する",
                    dueDate: .init(date: "昨日", time: "10:22"),
                    priority: .none,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "1日前", time: "9:37"),
                    lastModifiedDate: .init(date: "昨日", time: "13:37"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000023",
                    title: "ケーブルを整理する",
                    dueDate: .init(date: "今日", time: "8:52"),
                    priority: .low,
                    notes: "サンプルメモ 23",
                    isCompleted: false,
                    creationDate: .init(date: "1日前", time: "8:09"),
                    lastModifiedDate: .init(date: "昨日", time: "12:09"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000025",
                    title: "スマホの写真をバックアップする",
                    dueDate: .init(date: "今日", time: "10:04"),
                    priority: .none,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "5日前", time: "9:19"),
                    lastModifiedDate: .init(date: "昨日", time: "13:19"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000027",
                    title: "充電器を持ち出す",
                    dueDate: .init(date: "今日", time: "11:05"),
                    priority: .low,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "21日前", time: "9:19"),
                    lastModifiedDate: .init(date: "昨日", time: "13:19"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000035",
                    title: "パスワードを更新する",
                    dueDate: .init(date: "今日", time: "15:27"),
                    priority: .none,
                    notes: nil,
                    isCompleted: true,
                    creationDate: .init(date: "30日前", time: "10:44"),
                    lastModifiedDate: .init(date: "3日前", time: "14:44"),
                    completionDate: .init(date: "3日前", time: "14:44")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000067",
                    title: "スマホを充電する",
                    dueDate: .init(date: "2日後", time: "11:38"),
                    priority: .none,
                    notes: "サンプルメモ 67",
                    isCompleted: true,
                    creationDate: .init(date: "7日前", time: "8:48"),
                    lastModifiedDate: .init(date: "5日前", time: "12:48"),
                    completionDate: .init(date: "5日前", time: "12:48")
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000074",
                    title: "アプリをアップデートする",
                    dueDate: .init(date: "3日後", time: "11:02"),
                    priority: .low,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "3日前", time: "9:58"),
                    lastModifiedDate: .init(date: "今日", time: "13:58"),
                    completionDate: nil
                ),
                Reminder.sample(
                    id: "00000000-0000-0000-0000-000000000077",
                    title: "パソコンをバックアップする",
                    dueDate: .init(date: "4日後", time: "9:28"),
                    priority: .medium,
                    notes: nil,
                    isCompleted: false,
                    creationDate: .init(date: "21日前", time: "10:23"),
                    lastModifiedDate: .init(date: "昨日", time: "14:23"),
                    completionDate: nil
                ),
            ]
        )
    }
}
