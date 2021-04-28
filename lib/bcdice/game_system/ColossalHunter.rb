# frozen_string_literal: true

require "bcdice/format"

module BCDice
  module GameSystem
    class ColossalHunter < Base
      # ゲームシステムの識別子
      ID = 'ColossalHunter'

      # ゲームシステム名
      NAME = 'コロッサルハンター'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ころつさるはんたあ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定（CH±x>=y)
        　3D6の判定。クリティカル、ファンブルの自動判定を行います。
        　x：修正値。省略可能。y：目標値。省略可能。
        　例） CH　CH+1　CH+2>=10
        ・BIG-6表(B6T)
        ・覚醒表(AWT)
        ・現状表(CST)
        ・ハンターマーク表(HMT)
        ・特徴表(SPT)
        ・プレシャス表(PRT)
        ・専門能力表(EXT)
        ・コロッサル行動表(CAT)
        ・NPC作成表(CNP)
        ・D66ダイスあり
      MESSAGETEXT

      def initialize(command)
        super(command)
        @d66_sort_type = D66SortType::NO_SORT
      end

      def eval_game_system_specific_command(command)
        getCheckRollDiceCommandResult(command) ||
          getSourceSceneDiceCommandResult(command) ||
          getCreateNpcDiceCommandResult(command) ||
          getTableDiceCommandResult(command)
      end

      def getCheckRollDiceCommandResult(command)
        debug("getCheckRollDiceCommandResult command", command)

        parser = Command::Parser.new(/\d*CH/, round_type: round_type)
                                .restrict_cmp_op_to(nil, :>=)

        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        parsed.command = "3CH" unless parsed.command.start_with?(/\d/)

        dice_count = parsed.command.to_i
        modify = parsed.modify_number

        # ダイスロール
        dice_list = @randomizer.roll_barabara(dice_count, 6)
        dice = dice_list.sum()
        dice_str = dice_list.join(",")

        total = dice + modify

        # 出力文の生成
        result = "(#{parsed}) ＞ #{dice}[#{dice_str}]#{Format.modifier(modify)} ＞ #{total}"

        # クリティカル・ファンブルチェック
        if isFamble(dice)
          result += " ＞ ファンブル"
        elsif isCritical(total)
          result += " ＞ クリティカル"
        else
          result += getJudgeResultString(total, parsed)
        end

        return result
      end

      # 成否判定
      def getJudgeResultString(total, parsed)
        return '' if parsed.cmp_op.nil?

        return " ＞ 成功" if total >= parsed.target_number

        return " ＞ 失敗"
      end

      def isCritical(total)
        (total >= 16)
      end

      def isFamble(total)
        (total <= 5)
      end

      def getSourceSceneDiceCommandResult(command)
        return nil unless command =~ /^B6T$/

        name = "BIG-6表"
        table = getBig6Table
        yearTitle = "年齢"

        return getYearTableResult(name, table, yearTitle)
      end

      def getYearTableResult(name, table, yearTitle)
        item, index = get_table_by_d66(table)
        return nil if item.nil?

        title, text, yearText, = item
        debug('yearText', yearText)
        year, calculateText = getYear(yearText)

        result = "#{name}(#{index}) ＞ #{title}：#{text} ＞ #{yearTitle}：#{yearText}"
        result += " ＞ #{calculateText} ＞ #{yearTitle}：#{year}" unless year.nil?
        result += "歳"

        return result
      end

      def getYear(yearText)
        text = yearText.gsub(/(\d+)D(6+)/) { getD6xResult(Regexp.last_match(1).to_i, Regexp.last_match(2).length) }

        unless text.match?(%r{^[+\-*/\d]+$})
          return nil
        end

        if text.match?(/^\d+$/)
          return nil
        end

        year = ArithmeticEvaluator.eval(text)
        return year, "(#{text})"
      end

      def getD6xResult(count, dice6Count)
        total = 0

        count.times do |_i|
          number = 0

          dice6Count.times do |_i|
            number *= 10
            dice = @randomizer.roll_once(6)
            number += dice
          end

          total += number
        end

        return total.to_s
      end

      def getBig6Table
        table =
          [
            ["この世の地獄", "あれはまさに地獄。屍の山。嘆く者。呆然とする者。目の前で潰される者。あの日、人類は霊長ではなく……弱き獣の一種となった。", "15+2D6"],
            ["悪の時代", "全ての崩壊、呆然の時。救援が望めぬとわかったなら、少なからぬ者が悪に走った。あの頃は、あなたもまた下劣なる略奪者だった。", "18+2D6"],
            ["消えざる罪", "混乱の中、あなたは……私怨を晴らした。許せない人間を、その手で始末した。罪に問う者はいない……他ならぬあなた自身以外は。", "18+2D6"],
            ["言葉にできない", "ただ呆然と。廃人のようにあの期間を過ごした。目の前で何が起きていたかは覚えているけれど。思い出したくは……ない。", "任意（最低14）"],
            ["望む時代", "あの平和で膿んだ世界が嫌いだった。全てが壊れて、訪れた無法の時代。あなたは、あの日常が壊れた今を歓迎している。", "18+2D6"],
            ["あなたの呪い", "世界を怨み、自殺しようとした時、世界は変わった。あなたの呪詛が形になったように……コロッサルが全てを破壊し始めたのだ。", "任意（最低20）"],
            ["肉親の命日", "家族は、あなたの全てだった。だからあの日は、全てが失われた日だ。注ぐ愛も注がれる愛も、きっとあの日に枯れたのだ。", "任意（最低14）"],
            ["戦友の命日", "あなたとその仲間は無抵抗をよしとせず、コロッサルに立ち向かった。そして……あなた以外は全員が死んだ。彼らの分も生きなければ。", "30+3D6"],
            ["トラウマ", "あの日を思い出すだけで、震えが止まらず汗と涙が溢れ出す。忘れるためには、コロッサルと戦い続けるしかないだろう、きっと。", "任意（最低14）"],
            ["死を逃した時", "意識を失い、目覚めれば全ては壊れた後。生き延びたのは幸運なのか。不幸なのか。あるいはそれとも、呪いなのか。", "10+3D6"],
            ["呪縛", "あの時、無数の死を見た。その中で、ある一人が言った言葉が忘れられない。それは今も、あなたを縛る呪いとなっている。", "18+2D6"],
            ["ひっかかり", "あの日、配偶者あるいは恋人と別れた。恋の終わりと、世界の終わり。あれ以来、相手が生きているかもわからない……。", "25+3D6"],
            ["重症", "昏睡BIG-6で重い疵を負ったあなたは、長く昏睡状態だった。幸いにも人工冬眠装置によって、あなたは年を経ずに目を覚ましたが……。", "任意"],
            ["些末事", "あなたにはコロッサルの出現などよりも重要な目的がある。BIG-6など、どうでもよい。あなたは決して揺らぎはしないのだ。", "任意"],
            ["財産の消滅", "築き上げていた全てが失われた日。あなたにとって全てだった財貨も、権力も、消滅したあの日を、どうして忘れられようか。", "35+3D6"],
            ["告白未遂", "告白しようとしていたその日、コロッサルが現れた。崩れる日常。あの人が生きているのか、どうなったのか、何もわからない。", "18+2D6"],
            ["記憶喪失", "あの時、何があったのか、どうしても思い出せない。何か重大なことがあったはずなのに……思い出そうとすると頭痛が襲うのだ。", "任意（最低14）"],
            ["誕生の時", "BIG-6と同年、コロッサル襲撃の最中に生まれ、赤ん坊の状態で生存者らに保護された。親はわからない。あなたの生存は奇跡である。", "10"],
            ["ルーツ", "コロッサルによって破壊された瓦礫の合間に残されていた子……それがあなただ。親という概念すらなく、あなたは育ってきた。", "8+1D6"],
            ["伝え聞くのみ", "物心ついた時には周囲はコロッサルの脅威にさらされていた。BIG-6以前については何も知らない。遥か過去のようにすら思えている。", "8+1D6"],
            ["語られざること", "ZOSで育ったあなたには誰もBIG-6について教えてくれなかった。大人の会話の合間から、なんとなく想像するだけだ。", "8+1D6"],
            ["絵物語", "瓦礫でない建物。人が街にあふれかえる。なんという子供だましのおとぎ話だろう。あなたはBIG-6以前の存在を信じていない。", "8+1D6"],
            ["何それ", "隊商に見つけられるまで、獣同然に生きていた。BIG-6などあったことも知らない。物心ついた時には、餌を求め走っていたのだ。", "9+1D6"],
            ["嫉妬", "BIG-6時をあなたは覚えていない。そして、BIG-6以前の豊かさと平和に激しい嫉妬を抱き、守れなかった大人たちを恨む。", "9+1D6"],
            ["忘れたい記憶", "あなたはあの日を忘れようと努めた。今ではほとんど忘れたと言っていい。けれど、ふとした時にあの地獄の光景は現れて……。", "任意（最低14）"],
            ["始まりの時", "あなたにとってあれは終わりではなく、始まり。停滞して行き詰まった世界が動き出し、どうでもよかった己の命を感じさせてくれた瞬間。", "15+3D6"],
            ["かすかな記憶", "当時のあなたは幼かった。それでもうっすらと、あの平和で豊かだった時代を覚えている。いっそ知らなければ……と思うのだけれど。", "10+1D6"],
            ["崩壊と再生", "あなたの人生は、BIG-6による社会崩壊と……その後の再生をなぞるものだ。あなたはBIG-6以後を何より間近で見て来た。", "10+1D6"],
            ["他人事", "とても辺鄙な地方にいたせいか、コロッサルは出現しなかった。無論、影響はあったが……ゆっくりとしたもので。大災害の印象は薄い。", "6+3D6"],
            ["新たな時代", "まだマテリアルの価値が定かでなかった頃から、あなたはその価値に目を付けていた。応用法も含め……社会崩壊後に備えたのだ。", "任意（最低17）"],
            ["動乱", "当時は現役かつ、責任ある立場だった。守るために、あなたは全力で戦い、逃げ……そして時には同じ人間からも奪った。", "40+4D6"],
            ["自信の元", "あなたは一家の長として家族を守り、導いた。全てが破壊される中、家族は確かに生き延びて、あなた自身も未だ生き残れたのだ。", "35+3D6"],
            ["本能的記憶", "気が付けばゾーンに“いた”。コロッサルはさまざまな生物をクラフトする。中には小型のコロッサルとして独立して活動を開始するものもいるという。あなたもまた、気づいてほどなくハンターとして目覚めた。そう……あなたはクラフトされた存在。人よりもコロッサルに近い存在。記憶も感情も、どこまでが己のものなのか……。これは、およそ知られていい秘密ではない。（注意：外見年齢は任意）", "2D6-2"],
            ["体験無き事象", "あなたは母から生まれた人間ではなく、人工的なハンター作成の副産物たるクローニング技術の結晶だ。親は知らないが“作者”は知っている。肌にはバーコードが刻まれ、その体が通常の人間ではないと思い知らされるだろう。丁寧に記憶まで、一定量が流し込まれており、日常生活には支障がない。この出生は隠さねばならない。（注意：外見年齢は任意。覚醒表の内容は作られた記憶である）", "2D6-2"],
            ["特異点", "あのBIG-6の中では奇妙な時空のねじれが発生した。そして、あなたのようにありえざる時代や世界から、迷い込む者も現れたのだ。この事実は隠さねばならない……が、教えても誰も本気にはしないだろう。なお、あなたがどれほど特殊な能力や知識を持っていたとしても、データ上において他のPCと何ら変わらない。演出において、他の時代や異世界の知識や技術をいくらか使える程度である。", "任意（最低10）"],
            ["覚醒の時", "BIG-6時に絶望の中でコロッサルに抗い、生まれた第一世代のハンター。平和の時代を知る存在。そして平和を壊され、平和を取り戻さんと渇望する存在だ。ハンターの中でも、最初期であり最も経験豊富であり、同じハンターらからは敬意を捧げられる。もちろん、相応の振る舞いも求められるだろうが……。（注意：覚醒表における「ZOS」は、「故郷」か「組織」に変わる）", "任意（最低17）"],
          ]
        return table
      end

      def getCreateNpcDiceCommandResult(command)
        return nil unless command =~ /^CNP$/

        name = "NPC作成表"
        table = [
          ['ハンター嫌いの', 'ごろつき', '全てへの絶望'],
          ['心に傷を負った', '罪人', 'あなたへの殺意'],
          ['精神不安定な', '浮浪者', 'ハンターへの殺意'],
          ['病に伏した', '盗人', '己自身への殺意'],
          ['重傷を負った', '終末論者', 'ハンターへの憎悪'],
          ['悪名高い', '旅人', 'コロッサルへの崇拝'],
          ['横暴な', '難民', '人間への嫌悪'],
          ['あなたに依存している', '子供', 'あなたへの恐怖'],
          ['無謀な', '老人', '左隣PCへの殺意'],
          ['乱暴な', '少年', '窃盗への依存'],
          ['信用できない', '少女', '快楽への依存'],
          ['臆病な', '若者', '愛情への依存'],
          ['だらしない', '芸人', '未来への絶望'],
          ['短絡的な', '娼婦／男娼', '弱者への蔑視'],
          ['怠け者の', '元軍人', '己自身への嫌悪'],
          ['享楽的な', 'ハンター志願者', 'あなたへの疑念'],
          ['エキセントリックな', '元ハンター', 'ギャンブルへの依存'],
          ['ずる賢い', '労働者', 'アルコールへの依存'],
          ['恋人のいる', 'スカベンジャー', '孤独への恐怖'],
          ['残念な', '仕立て屋', 'ハンターへの恐怖'],
          ['空回りしている', '職人', 'コロッサルへの憎悪'],
          ['酒びたりの', '教師', 'ハンターへの不安'],
          ['妄想癖のある', '建築家', 'ハンターへの嫉妬'],
          ['努力家の', '商人', 'コロッサルへの恐怖'],
          ['やさしい', '料理人', '己の命への執着'],
          ['神秘的な', '漁師／猟師', 'あなたへの打算'],
          ['世馴れた', '農家', '過去への執着'],
          ['信用できる', '自警団員', 'マテリアルへの執着'],
          ['達観した', '看護師', 'ハンターへの憧憬'],
          ['血気盛んな', '研究者', 'あなたへの嫉妬'],
          ['美貌の', '技師', '異性への執着'],
          ['気高い', '医師', '力への渇望'],
          ['優秀な', '神父／シスター', 'ZOSへの依存'],
          ['天才肌の', '事務屋', '左隣PCへの執着'],
          ['誰からも愛される', '指導者', 'あなたへの羨望'],
          ['あなたに恋をしている', 'ハンター', 'あなたへの執着'],
        ]

        nature, nature_number = getD66Item(table, 0)
        type, type_number = getD66Item(table, 1)
        secret, secret_number = getD66Item(table, 2)

        result = "#{name}(#{nature_number}, #{type_number}, #{secret_number}) ＞ 性質：#{nature}／タイプ：#{type}／心の秘密：#{secret}"
        return result
      end

      def getD66Item(table, index)
        item, number = get_table_by_d66(table)
        return item[index], number
      end

      def getTableDiceCommandResult(command)
        info = TABLES[command]
        return nil if info.nil?

        name = info[:name]
        type = info[:type]
        table = info[:table]

        text, number =
          case type
          when '2D6'
            get_table_by_2d6(table)
          when '1D6'
            get_table_by_1d6(table)
          when 'D66'
            get_table_by_d66(table)
          end

        return nil if text.nil?

        return "#{name}(#{number}) ＞ #{text}"
      end

      TABLES =
        {

          'AWT' => {
            name: "覚醒表",
            type: 'D66',
            table: [
              '実験体：当時ハンターを人工的に作り出すべく、倫理を無視した研究が多数行われていた。あなたこそ、無数の犠牲の上に生まれた……数少ない成功作なのだ。',
              'ゾーン留置刑：刑罰としてコロッサルの進路に拘束され放置される罪人がいる。多くは命を落とすが、ハンターとして目覚める可能性もあるのだ。他ならぬあなたのように……。',
              'ハンター殺し：相応の理由はあったから。頭部への一撃で、非道のハンターを殺してやった。その報いか。その瞬間、あなた自身がハンターになってしまったのだ。',
              '目の前の変異：死んだハンターのコアが目の前でコロッサルと化す。しかし何という皮肉か。発生したゾーン。まき散らされるマテリアル。あなたはハンターとして覚醒した。',
              'ZOS壊滅：住んでいたZOSがコロッサルに蹂躙される。全てが破壊され、大切なものは全て失われる。無力感の中……皮肉にも、あなたは新たな力に目覚めた。',
              '生贄：ハンターのいない集団は時として奇妙な行為をする。弱者を生贄に捧げるのだ。それは、あなたというハンターを生み出し……集団はコロッサルに滅ぼされた。',
              '崩壊と追跡：ZOSの崩壊。誰も生き残らず。あなたは一人、復讐者と化して旅立つ。決意と覚悟が、あなたにハンターの力を与えてくれた。これは復讐の刃なのだ。',
              '臨死経験：コロッサルの一撃であなたは死んだ……だが、唯一無事だった脳がコアと化し、肉体を再構築し……あなたは再び立ち上がったのだ。',
              '脱走：実験施設か牢獄か、あるいは監禁場所か。あなたは死に物狂いで逃げ出した。偶然ゾーンに入っていたのか。あなたはハンターとなり、無事逃げ延びた。',
              '感情の暴発：それは狂気だったのかもしれない。あなたはその時、抑えきれぬ感情を爆発させ、ありえぬ行動を、ありえぬように行った。ハンターとして覚醒したのだ。',
              '肉体の欠損：まともな医療がないこの時代。体の一部を失う者は多い。あなたは絶望に呑まれず、失った体を、意志の力でクラフトした。そう、ハンターになったのだ。',
              '飢餓：荒野で飢え、渇き、あがいた。誰にも助けてもらえない中……幸運にもそのゾーンであなたは力に目覚める。鳥や獣を捕らえ貪り、生き延びたのだ。',
              '過剰な復讐：憎悪を募らせ、あなたは後先を考えず怨念の一撃を繰り出す。いつの間にか手には強大な武器があり、相手は建物ごと破壊された。憎悪に満ちた覚醒。',
              '遅すぎた覚醒：大切な人が死ぬ。故郷が破壊される。全てを失い、絶望に打ちひしがれながら、仇たるコロッサルの遥か背後で、ハンターとして覚醒した。何もかも手遅れなのに。',
              '贖罪の印：大切な人をあなた自身の手で殺してしまった。後悔と絶望の中、あなたはなぜかハンターとなる。それは己の贖罪のために与えられた力と思えた。',
              '瓦礫の闇：瓦礫の中、身動きは取れない。誰も助けてくれない。閉塞感と飢餓感と絶望、理不尽への怒り。最後まで足掻きに足掻いてハンターとして目覚め、脱出した。',
              '無謀なる突撃：ただ許せなかったのだ。故郷を蹂躙するコロッサルへ、武器とも呼べぬものを手に突撃する。ハンターとしての覚醒は、幸運の結果だったのだろう。',
              '残された遺志：コロッサルの襲撃の中、一人のハンターがあなたを守り……命を落とした。その後の残ったマテリアルに触れた瞬間、あなたはハンターとして覚醒したのだ。',
              '危機的覚醒：迫り来るコロッサルの一撃。けれど死を覚悟した瞬間、自身でも信じられない動きで攻撃を回避していた。そう、あなたはハンターになったのだ。',
              '猛る夜：その夜、あなたは恐怖と不安の中で、湧き上がる欲望のまま獣となって猛り、貪った。その欲望の一夜を経て、あなたは人を超えてハンターへと変わる。',
              'コロッサル接触：瀕死のあなたに、コロッサルが触れる。その瞬間、あなたはハンターとなり生き延びた。あのコロッサルはなぜ、人を救うようなことをしたのだろう？',
              '記憶喪失：何か大きな出来事があったはずなのだ。けれど思い出せない……いったいどうして、あなたがハンターとなったのか。かつて何があったのか、あなたは知りたい。',
              '偶然の獲得：ちっぽけな反抗、隔意、逃避。あなたはその日、ZOSを飛び出しコロッサルの領域内に立ち入ってしまい、偶然、ハンターとして目覚め、無事に生還した。',
              'ゾーン研究：あなたは学術的な興味から、ハンターに守られ何度もゾーンに入った。そして気づけば、あなた自身がハンターの力を得ていたのだ。',
              'ハンター志願：希望のない世界で、希望を得るため。多くは生きて帰れぬことを知りながら、コロッサルに立ち向かった。幸運にも……あなたはハンターとして覚醒できた。',
              '野生の日々：集団に属せず、あなたは半ば野生の中で一人生き延びていた。コロッサルにも狙われず、ゾーンで共存すらした。ハンターの力を得たのも必然だろう。',
              '自由落下：の中でふとした事故で、あなたは高所から落下した。けれど落下中、足場をクラフトし、あなたは九死に一生を得た。ハンターとして覚醒したのだ！',
              '昏睡：重傷を負って昏睡に陥り、夢の中で地の底からの囁きを聞いた。そして目覚めた時、あなたは能力にも目覚め、ハンターとなっていたのだ。',
              '極限の修練：愚直に信じて、信じて、信じて、嘲笑われても修練を繰り返した。努力の価値はわからない。それでもあなたは、己の覚醒を修練の結果だと信じている。',
              'ハンターとの恋：あなたの恋人はハンターだ。あるいは、ハンターだった。その交わりの中で、恋人のゾーンに深く影響され……気づけばハンターの能力を得ていた。',
              '恩人の危機：ZOSを守って来たハンター。逃げ遅れたあなた。目の前でハンターがコロッサルの一撃を受けて散ろうとするその瞬間……あなた自身が力に目覚めた。',
              '守る力：大切な人を守るため、迫り来るコロッサルの前であなたは目覚めた。新たな力は、コロッサルを倒し……あなたは無事に、守るべき人を守り切ったのだ。',
              '蟷螂の斧：たとえ無意味でも無価値でも、反抗の意を見せずにいられないから、あなたはコロッサルに立ち向かった。そして、己が無力ではないと、証明したのだ。',
              'ガイアの声：地の底から、呼びかける声を聞いた。コロッサルの傍にいたわけではない。しかし、その声を聞いた瞬間、あなたはハンターとなった。なってしまったのだ。',
              '天性のハンター：初めてコロッサルに対峙した時、自然にリクラフトして武装していた。しかも、歴戦のハンターと同等以上の巧みさで。あなたはこの時代、待望された天才だ。',
              'ありえぬ存在：BIG-6以前から、あるいはものごころつく以前から、ハンターの能力が開花していた。周囲の目は期待と不安、そして打算にまみれている。'
            ],
          },

          'CST' => {
            name: "現状表",
            type: 'D66',
            table: [
              '逃れえぬ恐怖：かつての悪夢は心を握りしめ、離してはくれない。平時は暗がりの隅で一人震え、ぶつぶつと呟くばかり。友らは、立ち直らせようとしてくれているが……。　リーダー度：2',
              '人間証明：いつからか自傷癖が身についてしまった。己が人間だと証明したいから。流れる血が赤いと知りたくて。己の手首を何度も何度も切り刻んでしまうのだ。　リーダー度：3',
              '裏切者：かつて、あなたはコロッサルと戦う仲間を見捨てて逃げ出した。連携は崩れ、多くの仲間が散った。以来、あなたを信用する者はいない。いるわけがない。　リーダー度：1',
              '人間不信：あなたは人々に裏切られ、罵られ、追放された身。ハンター同士ならまだしも、もはや人は信じられない。コロッサル以上に人間がおぞましいのだ。　リーダー度：2',
              '孤独：力を得れば、周囲は距離を取る。それがつらくて……逃げてしまった。もう人には関わらない。今や誰も近づいては来ない。あなたは独りぼっちなのだ。　リーダー度：2',
              '無法の首魁：力を得て増長したあなたには、多数の取り巻きがいる。暴虐も我儘も、ある程度は許されるのがハンターだ。今のあなたは、無法者の首領も同然である。　リーダー度：9',
              '生存者：何も守れず……あなたのZOSはコロッサルに破壊された。ただ一人……ハンターの力で生き延びたのだ。今はただ前へ足を進めるだけで精一杯。　リーダー度：3',
              '検体：乞われて研究者の検体に立候補した。あなたには何もない。どうされてもいい。力が手に入るならよし。誰かの礎になるならそれも……よし。　リーダー度：5',
              '刹那の快楽：何度出撃しようとも、コロッサルは恐ろしい。生きて戻ってくれば、次の出撃を恐れる。あなたは酒色に溺れ、現実から少しでも逃れようともがくだろう。　リーダー度：3',
              '戦闘機械：戦う以外は考えられなくなってしまった。何をすればいいのかわからないのだ。ただぼんやりと空を眺めているしか……することがない。　リーダー度：5',
              '亡霊を背負う：毎日、散っていった者たちの姿が脳裏に浮かぶ。彼らはあなたに力をくれるのだろうか。それとも、あなたを彼らと同じ場所へ導こうとしているのだろうか。　リーダー度：8',
              '雇用契約：大切な人を保護してもらう代わり、あなたはZOSのハンターになった。その人にはなかなか会えないけれど。きっと満足な生活を送っている……はずだ。　リーダー度：7',
              '鍛錬の日々：共にハンターとして組んで来た戦友がいた。今はもう全て土の下だ。彼らの分まで戦わねばならない。幸せになってはいけない。己の修練が全てだ。　リーダー度：9',
              '悪党の末路：悪事を重ね、ZOSを追放された。根無し草となり放浪する中、あなたの性根も少しは正されたろうか？　それとも逆恨みの炎は消えていないのか？　リーダー度：1',
              'ワーカホリック：恐怖があなたを働かせる。どんな雑務でもいいから仕事が必要だ。楽しみを知らないわけではないが……働いていないと、背後にまた恐怖が迫ってくる。　リーダー度：10',
              '虚ろな愛：恋人ないし配偶者がいる。しかし関係はもはや形だけ。その心はあなたに向いていない。心を向ける相手は別にいるのだ……しかし、それでも、あなたは。　リーダー度：6',
              '餓えしもの：今の世の中、マテリアルが金だ。コロッサルと戦えば戦うほど、あなたは財力と権力を得る。あなたは力に餓えて餓えて、戦いにも餓えているのだ。　リーダー度：8',
              '家族を背負い：病か老いか、あるいは重傷を負ってまともに働けない家族がいる。家族を養い、RIACTの保護を受けるためにも、あなたは働かねばならない。　リーダー度：7',
              '多情：こんな世の中では人の命は儚く、人の心もまた儚い。だからあなたは、いつも恋をして、いつも愛を囁いて。せめて己の軌跡を多くの人に残そうとする。　リーダー度：5',
              '人捜しの旅：かつて生き別れた大切な人を捜して、ZOSからZOSへと渡り歩いている。きっと、必ず、どこかで生き延びている……はずだ。　リーダー度：1',
              '善き狩人：特に働くわけではないが……あなたが披露する武勇伝は新世代を鼓舞し、ハンターへの憧れを抱かせる。人はコロッサルを恐れてばかりでは前に進めない。　リーダー度：8',
              'カジノ：ハンターならざる人々も、刹那的な享楽で全てを忘れようとしている。あなたは小さなカジノを営み、人々を楽しませる一方で、己の懐をあたためている。　リーダー度：4',
              '恋々的日々：あなたは恋人のためハンターとして活躍する。恋の中で日々は輝き、全ての悪夢はかき消される。今のあなたは、幸福な夢にどこまでも盲目でいられる。　リーダー度：9',
              '語り手：現実は、つらい。今の世には逃避する先が必要なのだ。だからはあなたは物語を読み漁り、時には自ら物語を書き、また時にはTRPGをする。　リーダー度：4',
              'スカベンジャー：崩壊した世界には隠されし謎・宝が無数にある。あなたは日々、廃墟を漁って機材や情報媒体を拾い集める。それは確かなZOSへの貢献となるのだ。　リーダー度：7',
              'エンジニア：機械いじりは楽しい。かつてあった文明の遺産から、新たなものを生み出す時、あなたは人類の前に広がる、明るい未来を信じられるのだ。　リーダー度：6',
              '医師：既に人と言えないハンターの体。しかし、それでも自らが何度も壊れ、再構成してきたからこそ……人の体を知る。平時のあなたは、ZOSの医師だ。　リーダー度：10',
              '訓練教官：最低限の自衛を覚えてもらうため。コロッサルについて若者らに教え、緊急時の対応を訓練する。その中にハンターとなる者もいるのだろうか？　リーダー度：12',
              '農家：コロッサルとの戦闘で少なからぬ人々が死ぬ。新たな命を芽生えさせ生かすべく……あなたは平時、農業に精を出している。農地と実りはあなたの宝だ。　リーダー度：11',
              '一家の主：恋人ないし配偶者がいる。もうすぐ家族は増えそうだ。未来は明るい。だから出撃したなら……きっと生きて、帰らねばならない。　リーダー度：10',
              'トレーダー：あなたはハンターである以上に商人だ。自らZOSからZOSへ商品を運び、マテリアルを獲得する。マテリアルの貯蓄が、今のあなたの生き甲斐だ。　リーダー度：4',
              'アイドル：荒廃した世界だからこそ、人には娯楽が必要だ。あなたは自らの歌や踊りで人々を鼓舞し、その心に輝きを取り戻さんとする。未来はきっと、明るいはずだ。　リーダー度：6',
              '自警団長：ZOSの治安はよくない。人々は皆、自暴自棄だ。ハンターにも不埒の輩は多い。あなたは人が人らしくあるべく、自警団を組織している。　リーダー度：12',
              '孤児院長：偽善と知りつつ、あなたは多数の孤児らを集め育てている。彼らを受け入れ、育てられるのはマテリアルを直接獲得してくるハンターくらいなのだ。　リーダー度：11',
              '導き手：自身も葛藤しつつ、あなたは宗教者として人に教えを説く。神に見放されたこの世界でも、心の支えは必要だ。人の心は救われねばならない。　リーダー度：11',
              '指導者：あなたはZOSの顔役だ。多くの人望を集め、ハンターの地位を向上させている。一挙一動が注目を受ける。気をひきしめて日々を過ごさねば。　リーダー度：12'
            ],
          },

          'HMT' => {
            name: "ハンターマーク表",
            type: 'D66',
            table: [
              '顔',
              '胸',
              '背中',
              '胴',
              '肩',
              '腕',
              '顔',
              '胸',
              '背中',
              '胴',
              '肩',
              '腕',
              '顔',
              '胸',
              '背中',
              '胴',
              '肩',
              '腕',
              '掌',
              '腿',
              '脛',
              '足裏',
              '全身',
              '片眼',
              '掌',
              '腿',
              '脛',
              '足裏',
              '全身',
              '片眼',
              '掌',
              '腿',
              '脛',
              '足裏',
              '全身',
              '片眼'
            ],
          },

          'SPT' => {
            name: "特徴表",
            type: 'D66',
            table: [
              '死んだ魚の目',
              '凶悪な容貌',
              '子供のように小柄',
              '目の下の隈',
              '疲れ切った背中',
              '威圧的な筋肉',
              'ガリガリの痩身cc',
              '中性的な顔立ち',
              '無数の傷痕',
              '顔に残る傷痕',
              '隻眼',
              '男装・女装',
              '樽のような肥満',
              '目立つ犬歯',
              'ぎらつく眼光',
              '奇妙なタトゥー',
              '見上げるような長身',
              '泣きボクロ',
              '滑らかな髪',
              '手入れされた髪型',
              '腰まで届くロングヘア',
              'ベリーショート',
              'ドレッド',
              'スキンヘッド',
              '特殊な形の瞳',
              '三白眼',
              'オッドアイ',
              '糸目',
              '眼鏡',
              '冷たい眼差し',
              'きれいな指',
              'すべやかな肌',
              '優しげな声',
              '明るい笑顔',
              '健康的な体',
              '整った容貌'
            ],
          },

          'PRT' => {
            name: "プレシャス表",
            type: 'D66',
            table: [
              '壊れたスマートフォン',
              '誰かの写真',
              '鳴らないヘッドホン',
              '記念の指輪',
              '血まみれの布',
              '空のスキットル（酒用の水筒）',
              '錆びたナイフ',
              '骨の欠片',
              '古い銃と弾丸1発',
              '銀の十字架',
              '謎の携帯メモリ',
              'インクが空の万年筆',
              '色あせたお守り',
              '使い込まれたパイプ',
              'よれた手帳',
              '読み込まれた本',
              'ケースに入った楽器',
              '綺麗な鈴',
              '写真の入ったロケット',
              '古びた鍵',
              '汚れた帽子',
              '片耳分のピアス',
              '一房の髪',
              '血塗られたストール',
              '裂けた服',
              'ヒビの入ったゴーグル',
              '壊れた眼鏡',
              '曇ったモノクル',
              '革製の眼帯',
              'ボロボロの財布',
              'よく手入れされた工具',
              '止まった腕時計',
              '子ども用の傘',
              '千切れたネックレス',
              '開かない懐中時計',
              '一組のダイス'
            ],
          },

          'EXT' => {
            name: "専門能力表",
            type: 'D66',
            table: [
              'メンタル　分類：準備',
              '宗教　分類：準備',
              '危険物　分類：準備',
              '化学　分類：準備',
              '狩猟　分類：準備',
              '警備　分類：準備',
              '採掘　分類：準備',
              'トレーニング　分類：準備',
              '輸送・保管　分類：準備',
              'サバイバル　分類：準備',
              '通信　分類：調査',
              '運転　分類：調査',
              '探偵　分類：調査',
              '地理　分類：調査',
              'ドローン　分類：調査',
              '交渉　分類：調査',
              '文献調査　分類：調査',
              'ＩＴ　分類：調査',
              '建築　分類：調査',
              '土木　分類：復興',
              '農業・畜産　分類：復興',
              '醸造　分類：復興',
              '教育　分類：復興',
              '公衆衛生　分類：復興',
              '治安　分類：復興',
              '電気　分類：復興',
              '機械　分類：復興',
              '芸術・芸能　分類：復興',
              '単純作業　分類：日常',
              'ゲーム　分類：日常',
              '調理　分類：日常',
              '医療　分類：日常',
              'スポーツ　分類：日常',
              'ナイトビジネス　分類：日常',
              '祭事　分類：日常',
              '商売　分類：日常'
            ],
          },

          'CAT' => {
            name: "コロッサル行動表",
            type: '1D6',
            table: [
              'ＺＯＷが急速に拡大してゆく！左右いずれかのエリアをＺＯＷにする。対象エリアはＺＯＷとなり、既存のイベントは消滅する。対象エリアは相談して選択し、そのエリアのイベントは消滅する。',
              'あのコロッサルの反応は……。コロッサルの情報をひとつ得る。',
              '何もしない。',
              '何もしない。',
              '何もしない。',
              '何もしない。'
            ],
          },

        }.freeze

      register_prefix("CH.*", "B6T", "CNP", TABLES.keys)
    end
  end
end
