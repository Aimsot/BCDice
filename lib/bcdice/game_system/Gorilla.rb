# frozen_string_literal: true

module BCDice
  module GameSystem
    class Gorilla < Base
      # ゲームシステムの識別子
      ID = 'Gorilla'

      # ゲームシステム名
      NAME = 'ゴリラTRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'こりらTRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        2D6ロール時のゴリティカル自動判定を行います。

        G = 2D6のショートカット

        例) G>=7 : 2D6して7以上なら成功
      MESSAGETEXT

      register_prefix('G.*')

      def change_text(string)
        string = string.gsub(/^(S)?G/i) { "#{Regexp.last_match(1)}2D6" }
        return string
      end

      def check_2D6(total, _dice_total, dice_list, cmp_op, target)
        return '' if target == '?'

        if dice_list == [5, 5]
          " ＞ ゴリティカル（自動的成功）"
        elsif total.send(cmp_op, target)
          " ＞ 成功"
        else
          " ＞ 失敗"
        end
      end
    end
  end
end
