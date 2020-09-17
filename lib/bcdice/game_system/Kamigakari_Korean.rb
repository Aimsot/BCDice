# frozen_string_literal: true

module BCDice
  module GameSystem
    class Kamigakari_Korean < Base
      # ゲームシステムの識別子
      ID = 'Kamigakari:Korean'

      # ゲームシステム名
      NAME = '카미가카리'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:카미가카리'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・각종표
         ・감정표(ET)
         ・영문소비의 댓가표(RT)
         ・전기 성씨・이름 결정표(NT)
         ・마경임계표(KT)
         ・획득 소재 차트(MTx x는［법칙장해］의［강도］.생략할 때는１)
        　　예） MT　MT3　MT9
        ・D66주사위 가능
      INFO_MESSAGE_TEXT

      register_prefix([
        'RT',
        'MT(\d*)',
        'ET',
        'NT',
        'KT'
      ])

      def initialize
        super

        @sort_add_dice = true
        @enabled_d66 = true
        @d66_sort_type = D66SortType::NO_SORT
      end

      def eval_game_system_specific_command(command)
        tableName = ""
        result = ""

        debug("eval_game_system_specific_command command", command)

        case command

        when "RT"
          tableName, result, number = getReimonCompensationTableResult

        when /^MT(\d*)$/
          rank = Regexp.last_match(1)
          rank ||= 1
          rank = rank.to_i
          tableName, result, number = getGetMaterialTableResult(rank)

        when "ET"
          tableName, result, number = getEmotionTableResult

        when "NT"
          tableName, result, number = getNameTableResult

        when "KT"
          tableName, result, number = getKyoukaiTableResult

        else
          debug("eval_game_system_specific_command commandNOT matched -> command:", command)
          return ""
        end

        if result.empty?
          return ""
        end

        text = "#{tableName}(#{number})：#{result}"
        return text
      end

      def getReimonCompensationTableResult
        tableName = "영문소비의 댓가표"

        table = [
          '사신화：물리법칙을 너무 초월한 대가로, 영혼이 왜곡되어, PC는 즉시 아라미타마로 변모한다. 아라미타마화한 PC는, 어딘가로 떠나간다.',
          '존재소멸：아라미타마화를 최후의 힘으로 억누른다. 하지만 그 결과, PC의 영혼은 불타버려, 이 세계에서 소멸한다. 그 PC는 [상태변화: 사망]이 되어, 시체도 남지 않는다.',
          '사망：영혼의 왜곡을 어떻게든 막지만, 영혼이 붕괴한다. PC는 [상태변화: 사망]이 되나 유체는 남는다.',
          '영혼반괴：영혼의 왜곡을 막아냈지만, 영혼 자체에 치명적인 부상을 입어, 전신에 장해가 남는다. 거기에 동반하여 영문도 소실해, 일반인으로 돌아간다.',
          '기억소멸：기적적으로, 영혼의 마모에 의한 신체적 악영향을 피한다. 시간을 두는 것으로 영문도 회복되나, 정신적인 영향을 받아, 모든 기억을 잃는다.',
          '영향없음：기적적으로, 영혼의 마모에 의한 악영향을 완전히 피하고, 또한 영문의 회복도 빠를 것으로 보인다. 육체나 정신 모두, 딱히 영향은 없다.',
        ]
        result, number = get_table_by_1d6(table)

        return tableName, result, number
      end

      def getEmotionTableResult
        tableName = "감정표"

        table = [
          [11, '운명/그 캐릭터에게, 운명적, 또는 숙명적인 것을 느끼고 있다.'],
          [12, '운명/그 캐릭터에게, 운명적, 또는 숙명적인 것을 느끼고 있다.'],
          [13, '가족/그 캐릭터에게, 가족같은 친근감을 품고 있다.'],
          [14, '가족/그 캐릭터에게, 가족같은 친근감을 품고 있다.'],
          [15, '악연/그 캐릭터에게, 악연을 느끼고 있다.'],
          [16, '악연/그 캐릭터에게, 악연을 느끼고 있다.'],
          [21, '사제/그 캐릭터와는, 마치 사제지간의 감정을 느끼고 있다. 누가 제자고 누가 스승인지, 플레이어 끼리(또는 GM과)상담해 결정한다.'],
          [22, '사제/그 캐릭터와는, 마치 사제지간의 감정을 느끼고 있다. 누가 제자고 누가 스승인지, 플레이어 끼리(또는 GM과)상담해 결정한다.'],
          [23, '호적수/그 캐릭터를, 호적수라 여기고 있다.'],
          [24, '호적수/그 캐릭터를, 호적수라 여기고 있다.'],
          [25, '친근감/그 캐릭터에게, 친근감을 품고 있다.'],
          [26, '친근감/그 캐릭터에게, 친근감을 품고 있다.'],
          [31, '성의/그 캐릭터에게, 성실함을 느끼고 있다.'],
          [32, '성의/그 캐릭터에게, 성실함을 느끼고 있다.'],
          [33, '우정/그 캐릭터에게, 우정을 품고 있다.'],
          [34, '우정/그 캐릭터에게, 우정을 품고 있다.'],
          [35, '존경/그 캐릭터에게, 존경을 품고 있다.'],
          [36, '존경/그 캐릭터에게, 존경을 품고 있다.'],
          [41, '비호/그 캐릭터에게, 비호의 감정을 품고 있다. 누가 보호자고 누가 피보호자인지, 플레이어 끼리(또는 GM과)상담해 결정한다.'],
          [42, '비호/그 캐릭터에게, 비호의 감정을 품고 있다. 누가 보호자고 누가 피보호자인지, 플레이어 끼리(또는 GM과)상담해 결정한다.'],
          [43, '호감/그 캐릭터에게, 호감을 품고 있다.'],
          [44, '호감/그 캐릭터에게, 호감을 품고 있다.'],
          [45, '흥미/그 캐릭터에게, 흥미를 품고 있다.'],
          [46, '흥미/그 캐릭터에게, 흥미를 품고 있다.'],
          [51, '감명/그 캐릭터에게, 감명을 느끼고 있다.'],
          [52, '감명/그 캐릭터에게, 감명을 느끼고 있다.'],
          [53, '외경/그 캐릭터를 두려워하고 있다.'],
          [54, '외경/그 캐릭터를 두려워하고 있다.'],
          [55, '마음에 듬/그 캐릭터를 마음에 들어한다.'],
          [56, '마음에 듬/그 캐릭터를 마음에 들어한다.'],
          [61, '애정/그 캐릭터에게 애정, 또는 거기에 가까운 집착심을 품고 있다.'],
          [62, '애정/그 캐릭터에게 애정, 또는 거기에 가까운 집착심을 품고 있다.'],
          [63, '신뢰/그 캐릭터에게 신뢰를 느끼고 있다.'],
          [64, '신뢰/그 캐릭터에게 신뢰를 느끼고 있다.'],
          [65, '＊PC의 임의/플레이어, 또는 GM이 설정한 임의의 감정을 품고 있다.'],
          [66, '＊PC의 임의/플레이어, 또는 GM이 설정한 임의의 감정을 품고 있다.'],
        ]

        number = @randomizer.roll_d66(D66SortType::NO_SORT)

        result = get_table_by_number(number, table)

        return tableName, result, number
      end

      def getNameTableResult
        tableName = "전기 성씨・이름 결정표"

        table = [
          [11, '미츠루기(御剣)　리쿠/린'],
          [12, '시시우치(獅子内)　야마토/카에데'],
          [13, '하쿠긴(白銀)　하야토/사쿠라'],
          [14, '타케노우치(竹内)　마코토/하루카'],
          [15, '코다치(古太刀)　다이치/미사'],
          [16, '쿠가(空閑)　슌/마오'],
          [21, '오니가타(鬼形)　료/마이'],
          [22, '미칸나기(御巫)　타쿠미/나나미'],
          [23, '고마도우(護摩堂)　히토시/치히로'],
          [24, '류엔(龍円)　타쿠마/아카네'],
          [25, '카가미베(鏡部)　쿄우/아스카'],
          [26, '이누가미(犬神)　코우/시오리'],
          [31, '메이게츠인(明月院)　아오이/유이'],
          [32, '도우메키(百目鬼)　렌야/모에'],
          [33, '오소가미(怨神)　타츠야/아야카'],
          [34, '아라라기(蘭)　류노스케/아즈사'],
          [35, '타마키(珠輝)　아키라/히토미'],
          [36, '간류(眼龍)　케이/사오리'],
          [41, '텟포즈카(鉄砲塚)　마사토/사라'],
          [42, '오리가미(檻神)　나오야/야요이'],
          [43, '후지와라(不死原)　쥰/치아키'],
          [44, '쿠로우자(九朗座)　무사시/하루나'],
          [45, '츠치미카도(土御門)　쿄스케/스이'],
          [46, '이자요이(十六夜)　케이지/후타바'],
          [51, '텐포우린(転法輪)　히로/레나'],
          [52, '시교우(執行)　히비키/사유리'],
          [53, '호우리(祝)　료타로/히나'],
          [54, '코우소(神尊)　토모/시온'],
          [55, '아시야(芦屋)　타카유키/카스미'],
          [56, '나나샤(七社)　카즈키/후카'],
          [61, '키바(騎馬)　테츠야/시노'],
          [62, '토우마(当麻)　켄/사야'],
          [63, '키츠네즈카(狐塚)　호쿠토/마야'],
          [64, '텐진바야시(天神林)　소라/아키라'],
          [65, '메아라시(明嵐)　야쿠모/오토하'],
          [66, '쿠사카베(草壁)　다이고/아야'],
        ]

        number = @randomizer.roll_d66(D66SortType::NO_SORT)

        result = get_table_by_number(number, table)

        return tableName, result, number
      end

      def getKyoukaiTableResult
        tableName = "마경임계표"

        table = [
          [11, "시공의 비틀림\n현재 위치의 시공이 비틀려, PC전원은 즉시 [침입 에리어]로 돌아간다."],
          [12, "시공의 비틀림\n현재 위치의 시공이 비틀려, PC전원은 즉시 [침입 에리어]로 돌아간다."],
          [13, "강적등장\n갑자기, 〈재앙신〉화한 [모노노케]가 출현한다. GM은 PC의 [세계간섭LV]의 평균+3의 [LV]을 가진 임의의 [모노노케]를 1체 골라, 임의의 [탐색 에리어]에 배치. 거기서는 [우회]불가로 [전투]가 발생한다."],
          [14, "강적등장\n갑자기, 〈재앙신〉화한 [모노노케]가 출현한다. GM은 PC의 [세계간섭LV]의 평균+3의 [LV]을 가진 임의의 [모노노케]를 1체 골라, 임의의 [탐색 에리어]에 배치. 거기서는 [우회]불가로 [전투]가 발생한다."],
          [15, "그림자의 손\n장기로 형성된 무수한 손이, PC들을 붙잡으려고 한다. PC전원은 [효과종류: 마법공격/거리: 전투지대/대상: 전투지대/달성치: 20+PC의 [세계간섭LV]의 평균/마법 데미지: 20×PC의 [세계간섭LV]의 평균/저항[반감]]을 받는다."],
          [16, "그림자의 손\n장기로 형성된 무수한 손이, PC들을 붙잡으려고 한다. PC전원은 [효과종류: 마법공격/거리: 전투지대/대상: 전투지대/달성치: 20+PC의 [세계간섭LV]의 평균/마법 데미지: 20×PC의 [세계간섭LV]의 평균/저항[반감]]을 받는다."],
          [21, "무수한 마안\n공간 전체게 무시무시한 마안이 출현한다. PC전원은 [대휴식]할 때까지 [상태변화: 암흑·고통]이 된다."],
          [22, "무수한 마안\n공간 전체게 무시무시한 마안이 출현한다. PC전원은 [대휴식]할 때까지 [상태변화: 암흑·고통]이 된다."],
          [23, "공간붕괴\n갑자기, 마경의 공간이 붕괴한다. PC전원은 [효과종류: 물리공격/거리: 전투지대/대상: 전투지대/달성치: 30+PC의 [세계간섭LV]의 평균/물리 데미지: 30×PC의 [세계간섭LV]의 평균]을 받는다."],
          [24, "공간붕괴\n갑자기, 마경의 공간이 붕괴한다. PC전원은 [효과종류: 물리공격/거리: 전투지대/대상: 전투지대/달성치: 30+PC의 [세계간섭LV]의 평균/물리 데미지: 30×PC의 [세계간섭LV]의 평균]을 받는다."],
          [25, "방어구 부식\n이질적인 안개가 나타나, 방어구를 부식시킨다. PC전원은, [소지·장비]중인 임의의 [아이템: 방어구]를 1개 잃는다."],
          [26, "방어구 부식\n이질적인 안개가 나타나, 방어구를 부식시킨다. PC전원은, [소지·장비]중인 임의의 [아이템: 방어구]를 1개 잃는다."],
          [31, "소재소실\n주변에서 수상한 빛이 떨어져, 소지 중인 [소재]를 소실시킨다. PC 전원이 [소지]중인 [소재]가 전부 소멸한다."],
          [32, "소재소실\n주변에서 수상한 빛이 떨어져, 소지 중인 [소재]를 소실시킨다. PC 전원이 [소지]중인 [소재]가 전부 소멸한다."],
          [33, "없음\n딱히 아무 일도 일어나지 않는다."],
          [34, "없음\n딱히 아무 일도 일어나지 않는다."],
          [35, "모노노케 강습\n갑자기, 〈재앙신〉화한 [모노노케]가 출현해, PC들을 덮친다. GM은 PC의 [세계간섭LV]의 평균+2의 [LV]을 가진 임의의 [모노노케]를 2체 골라, PC의 앞에 출현시키고, 즉시 [전투]를 개시한다."],
          [36, "모노노케 강습\n갑자기, 〈재앙신〉화한 [모노노케]가 출현해, PC들을 덮친다. GM은 PC의 [세계간섭LV]의 평균+2의 [LV]을 가진 임의의 [모노노케]를 2체 골라, PC의 앞에 출현시키고, 즉시 [전투]를 개시한다."],
          [41, "휴식방해\nPC가 휴식하려고 할 때마다, 다양한 공간에서 촉수나 독충 등이 출현해 덮쳐든다. PC들은 이후, [마경토벌]이 종료될 때까지 [대휴식]을 할 수 없다."],
          [42, "휴식방해\nPC가 휴식하려고 할 때마다, 다양한 공간에서 촉수나 독충 등이 출현해 덮쳐든다. PC들은 이후, [마경토벌]이 종료될 때까지 [대휴식]을 할 수 없다."],
          [43, "용맥파괴\n영력이 폭주해 공간이 일그러져, [영력]이 어그러진다. PC전원은 즉시 [영력]을 모두 다시 굴린다."],
          [44, "용맥파괴\n영력이 폭주해 공간이 일그러져, [영력]이 어그러진다. PC전원은 즉시 [영력]을 모두 다시 굴린다."],
          [45, "고유시간정지\nPC들의 육체의 일부가 잿빛으로 변하고, 움직일 수 없게 된다. PC 전원은, [타이밍: 준비·방어·특수]에서 1개 골라, 이후 그 [타이밍]을 소비할 수 없게 된다."],
          [46, "고유시간정지\nPC들의 육체의 일부가 잿빛으로 변하고, 움직일 수 없게 된다. PC 전원은, [타이밍: 준비·방어·특수]에서 1개 골라, 이후 그 [타이밍]을 소비할 수 없게 된다."],
          [51, "용맥불순\n영력이 갑자기 고갈되어, [영력]의 순환에 악영향이 발생한다. PC전원은 이후, [마경토벌]이 종료될 때까지 [영력조작]을 할 수 없다."],
          [52, "용맥불순\n영력이 갑자기 고갈되어, [영력]의 순환에 악영향이 발생한다. PC전원은 이후, [마경토벌]이 종료될 때까지 [영력조작]을 할 수 없다."],
          [53, "술식봉인\n주변의 공기가 변모해, 악영향이 일어난다. PC전원은 이후, 취득한 《탤런트》중, 사용하는 [코스트]가 가장 큰 것 1개가 [마경토벌]종료까지 사용불능이 된다. [코스트: 없음]뿐일 경우, GM이 임의로 1개 결정한다."],
          [54, "술식봉인\n주변의 공기가 변모해, 악영향이 일어난다. PC전원은 이후, 취득한 《탤런트》중, 사용하는 [코스트]가 가장 큰 것 1개가 [마경토벌]종료까지 사용불능이 된다. [코스트: 없음]뿐일 경우, GM이 임의로 1개 결정한다."],
          [55, "장식품 소멸\n주변이 푸른 빛으로 감싸이고, 어째선지 PC들의 장식품이 사라진다. PC전원은, [소지·장비]중인 [아이템: 장식]을 모두 잃는다.。"],
          [56, "장식품 소멸\n주변이 푸른 빛으로 감싸이고, 어째선지 PC들의 장식품이 사라진다. PC전원은, [소지·장비]중인 [아이템: 장식]을 모두 잃는다."],
          [61, "우자의 황금 소실\n주변이 붉은 빛으로 감싸이고, 어째선지 PC들의 [G]가 사라진다. PC 전원은, [소지금]이 [반감]한다."],
          [62, "우자의 황금 소실\n주변이 붉은 빛으로 감싸이고, 어째선지 PC들의 [G]가 사라진다. PC 전원은, [소지금]이 [반감]한다."],
          [63, "GM의 임의\n이 표 중에서 GM이 효과를 1개 골라 발생시킨다."],
          [64, "GM의 임의\n이 표 중에서 GM이 효과를 1개 골라 발생시킨다."],
          [65, "임계중복\n[마경임계]가 2번 발생한다. GM은 이 표를 2번 굴려, 효과를 각각 적용할 수 있다. 다시 「임계중복」이 발생한 경우, [GM의 임의] 1번으로 취급한다."],
          [66, "임계중복\n[마경임계]가 2번 발생한다. GM은 이 표를 2번 굴려, 효과를 각각 적용할 수 있다. 다시 「임계중복」이 발생한 경우, [GM의 임의] 1번으로 취급한다."],
        ]

        number = @randomizer.roll_d66(D66SortType::NO_SORT)

        result = get_table_by_number(number, table)

        return tableName, result, number
      end

      def getGetMaterialTableResult(rank)
        tableName = "획득 소재 차트"
        table = [
          '진홍의 ',
          '까끌까끌한 ',
          '비취의 ',
          '예리한 ',
          '황금의 ',
          '말랑말랑한 ',
          '은색의 ',
          '뾰족한 ',
          '순백의 ',
          '딱딱한 ',
          '칠흑의 ',
          '빛나는 ',
          '매끄러운 ',
          '탁한 ',
          '덥수룩한 ',
          '사악한 ',
          '끈적이는 ',
          '성스러운 ',
          '작열의 ',
          '불꽃의 ',
          '빙결의 ',
          '얼음의 ',
          '뜨거운 ',
          '바람의 ',
          '차가운 ',
          '번개의 ',
          '흙의 ',
          '환상의 ',
          '뼈형태의 ',
          '봉인의 ',
          '이빨형태의 ',
          '비늘형태의 ',
          '돌형태의 ',
          '보석형태의 ',
          '모피형태의 ',
          '깃털형태의 ',
        ]

        result, number = get_table_by_d66(table)
        result += "단편"

        effect, number2 = getMaterialEffect(rank)
        number = "#{number},#{number2}"

        price = getPrice(effect)

        result = "#{result}.#{effect}"
        result += "：#{price}" unless price.nil?

        return tableName, result, number
      end

      def getMaterialEffect(rank)
        number = @randomizer.roll_once(6)

        result = ""
        type = ""
        if number < 6
          result, number2 = getMaterialEffectNomal(rank)
          type = "자주 발견되는 소재"
        else
          result, number2 = getMaterialEffectRare()
          type = "드문 소재"
        end

        result = "#{type}：#{result}"
        number = "#{number},#{number2}"

        return result, number
      end

      def getMaterialEffectNomal(rank)
        table = [
          [13, '체력+n'],
          [16, '민첩+n'],
          [23, '지성+n'],
          [26, '정신+n'],
          [33, '행운+n'],
          [35, '물D+n'],
          [41, '마D+n'],
          [43, '행동+n'],
          [46, '생명+n×3'],
          [53, '장갑+n'],
          [56, '결계+n'],
          [63, '이동+n마스'],
          [66, '※PC의 임의'],
        ]

        number = @randomizer.roll_d66(D66SortType::NO_SORT)

        result = get_table_by_number(number, table)
        debug("getMaterialEffectNomal result", result)

        if result =~ /\+n/
          power, number2 = getMaterialEffectPower(rank)

          result = result.sub(/\+n/, "+#{power}")
          number = "#{number},#{number2}"
        end

        return result, number
      end

      def getMaterialEffectPower(rank)
        table = [
          [4, [1, 1, 1, 2, 2, 3]],
          [8, [1, 1, 2, 2, 3, 3]],
          [9, [1, 2, 3, 3, 4, 5]],
        ]

        rank = 9 if rank > 9
        rankTable = get_table_by_number(rank, table)
        power, number = get_table_by_1d6(rankTable)

        return power, number
      end

      def getMaterialEffectRare()
        table = [[3, '**부여'],
                 [5, '**반감'],
                 [6, '※GM의 임의'],]

        number = @randomizer.roll_once(6)
        result = get_table_by_number(number, table)
        debug('getMaterialEffectRare result', result)

        if result =~ /\*\*/
          attribute, number2 = getAttribute()
          result = result.sub(/\*\*/, attribute.to_s)
          number = "#{number},#{number2}"
        end

        return result, number
      end

      def getAttribute()
        table = [
          [21, '［화염］'],
          [33, '［냉기］'],
          [43, '［전격］'],
          [53, '［풍압］'],
          [56, '［환각］'],
          [62, '［마독］'],
          [64, '［자력］'],
          [66, '［섬광］'],
        ]

        number = @randomizer.roll_d66(D66SortType::NO_SORT)

        result = get_table_by_number(number, table)

        return result, number
      end

      def getPrice(effect)
        power = 0

        case effect
        when /\+(\d+)/
          power = Regexp.last_match(1).to_i
        when /부여/
          power = 3
        when /반감/
          power = 4
        else
          power = 0
        end

        table = [nil,
                 '500G(효과치:1)',
                 '1000G(효과치:2)',
                 '1500G(효과치:3)',
                 '2000G(효과치:4)',
                 '3000G(효과치:5)',]
        price = table[power]

        return price
      end
    end
  end
end
