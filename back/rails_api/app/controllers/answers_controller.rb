class AnswersController < ApplicationController

  def answers
    # ユーザが選んだ選択肢を受け取る。
    choices = params[:choices]


    # yamlの質問と選択肢を全て持ってくる。
    questions = YAML.load_file("public/questions.yml")
    # ユーザの選んだ選択肢(index)が持つ趣向値を入れる配列を作る。
    taste_values = []
    # ユーザが選んだ選択肢の趣向値をyamlから取って、配列に入れる。
    questions.each_with_index do |question, index|
      taste_values << question["values"][choices[index]]
    end
    # 趣向値をだけを配列に入れる
    user_taste_values = taste_values.map{|v| v.values}.flatten!


    # 全てのカードの趣向値を配列にいれる。
    cards_taste_values = Card.pluck(:age, :points, :miles, :annual_fee)


    # |ユーザ趣向値 - カードの趣向値| この計算を全カード分行う。  
    different_values = cards_taste_values.map do |v|
      [user_taste_values, v].transpose.map{|a| a.inject(:-).abs}
    end
    # アンマッチ度の算出(arrayの中の足し算)
    arrays_sum = different_values.map{|v| v.sum.round(2)}
    # アンマッチ度にindexをつけて、hash化する。
    sums_with_id = {}
    arrays_sum.each_with_index do |sum,index|
      sums_with_id.merge!(index+1 => sum)
    end
    # アンマッチ度をもとにマッチしている順番に並べ、上位三つのindexを取得する。
    much_cards_index = sums_with_id.sort_by { |_, v| v }.to_h.keys.take(3)

    # マッチしている上位三つのindexをもとに、DBからCardを引っ張る。
    cards = Card.where(id: much_cards_index).order_as_specified(id: much_cards_index)
    # Nuxt側にjson形式でマッチしたcardの情報を返す。
    render json: cards, status: 200
  end

end
