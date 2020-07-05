require 'rails_helper'

RSpec.describe '商品出品', type: :system do
  before do
    @user = FactoryBot.create(:user)
    @item = FactoryBot.build(:item)
  end
  context '商品出品ができるとき' do 
    it '有効な情報を入力すると、レコードが1つ増え、トップページへ遷移すること' do
      # ログインする
      visit new_user_session_path
      fill_in 'user[email]', with: @user.email
      fill_in 'user[password]', with: @user.password
      find('input[name="commit"]').click
      expect(current_path).to eq root_path
      # 出品ページへのリンクがある
      expect(page).to have_content('出品する')
      # 出品ページへのリンクをクリックする
      visit new_item_path
      # フォームに情報を入力する
      page.attach_file('item[image]', "#{Rails.root}/spec/fixtures/sample.png")
      fill_in 'item[name]', with: @item.name
      fill_in 'item[info]', with: @item.info
      select "レディース", from: "item[category_id]"
      select "新品、未使用", from: "item[sales_status_id]"
      select "着払い(購入者負担)", from: "item[shipping_fee_status_id]"
      select "北海道", from: "item[prefecture_id]"
      select "1~2日で発送", from: "item[scheduled_delivery_id]"
      fill_in 'item[price]', with: @item.price
      # 出品ボタンを押すとアイテムモデルのカウントが1上がる
      expect{
        find('input[name="commit"]').click
      }.to change { Item.count }.by(1)
      # トップページへ遷移する
      expect(page).to have_current_path(root_path)
    end
  end
  context '商品出品ができないとき' do 
    it '無効な情報で商品出品を行うと、商品出品ページにて、エラーメッセージ が表示されること' do
      # ログインする
      visit new_user_session_path
      fill_in 'user[email]', with: @user.email
      fill_in 'user[password]', with: @user.password
      find('input[name="commit"]').click
      expect(current_path).to eq root_path
      # 出品ページへのリンクがある
      expect(page).to have_content('出品する')
      # 出品ページへのリンクをクリックする
      visit new_item_path
      # フォームに情報を入力する
      fill_in 'item[name]', with: ""
      fill_in 'item[info]', with: ""
      fill_in 'item[price]', with: ""
      # 出品ボタンを押してもアイテムモデルのカウントは上がらない
      expect{
        find('input[name="commit"]').click
      }.to change { Item.count }.by(0)
      # 出品ページへ戻される
      expect(page).to have_content("商品の情報を入力")
      # エラーメッセージのクラスが出現する
      expect(page).to have_css "div.error-alert" 
    end
    it 'ログインしていない状態で商品出品ページへアクセスすると、ログインページへ遷移すること' do
      visit root_path
      # 出品ページへのリンクがある
      expect(page).to have_content('出品する')
      # 出品ページへのリンクをクリックする
      visit new_item_path
      # ログイン画面へ遷移する
      expect(page).to have_content("会員情報入力")
      # エラーメッセージが出現している
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end
end

RSpec.describe '商品編集', type: :system do
  before do
    @item1 = FactoryBot.create(:item, :image)
    @item2 = FactoryBot.create(:item, :image)
  end
  context '商品編集ができるとき' do
    it '有効な情報で商品編集を行うと、レコードが更新され、商品詳細ページへ遷移し、商品出品時に入力した値が表示されていること' do
      visit new_user_session_path
      fill_in 'user[email]', with: @item1.user.email
      fill_in 'user[password]', with: @item1.user.password
      find('input[name="commit"]').click
      expect(current_path).to eq root_path
      # 表示されている商品をクリック
      find(:xpath, "//a[@href='/items/#{@item1.id}']").click
      # アイテム1に「商品の編集」ボタンがある
      expect(page).to have_link '商品の編集', href: edit_item_path(@item1)
      # 編集ページへ遷移する
      visit edit_item_path(@item1)
      # すでに投稿済みの内容がフォームに入っている(画像以外)
      expect(
        find('#item_name').value
      ).to eq @item1.name
      expect(
        find('#item_info').value
      ).to eq @item1.info
      expect(
        find('#item_category_id').value
      ).to eq "#{@item1.category_id}"
      expect(
        find('#item_sales_status_id').value
      ).to eq "#{@item1.sales_status_id}"
      expect(
        find('#item_shipping_fee_status_id').value
      ).to eq "#{@item1.shipping_fee_status_id}"
      expect(
        find('#item_prefecture_id').value
      ).to eq "#{@item1.prefecture_id}"
      expect(
        find('#item_scheduled_delivery_id').value
      ).to eq "#{@item1.scheduled_delivery_id}"
      expect(
        find('#item_price').value
      ).to eq "#{@item1.price}"
      # 投稿内容を編集する
      page.attach_file('item[image]',"#{Rails.root}/spec/fixtures/sample2.png")
      fill_in 'item[name]', with: "#{@item1.name}+編集したテキスト"
      # 編集してもItemモデルのカウントは変わらない
      expect{
        find('input[name="commit"]').click
      }.to change { Item.count }.by(0)
      # 「商品の編集」の文字がある
      expect(page).to have_content('商品の編集')
      # トップページに遷移する
      visit root_path
      # トップページには先ほど変更した内容のツイートが存在する（画像）
      expect(page).to have_selector("img[src$='sample2.png']")
      # トップページには先ほど変更した内容のツイートが存在する（テキスト）
      expect(page).to have_content("#{@item1.name}+編集したテキスト")
    end
  end
  context '商品編集ができないとき' do
    it '無効な情報で商品編集を行うと、商品編集ページにて、エラーメッセージ が表示されること' do
      visit new_user_session_path
      fill_in 'user[email]', with: @item1.user.email
      fill_in 'user[password]', with: @item1.user.password
      find('input[name="commit"]').click
      expect(current_path).to eq root_path
      # 表示されている商品をクリック
      find(:xpath, "//a[@href='/items/#{@item1.id}']").click
      # アイテム1に「商品の編集」ボタンがある
      expect(page).to have_link '商品の編集', href: edit_item_path(@item1)
      # 編集ページへ遷移する
      visit edit_item_path(@item1)
      # すでに投稿済みの内容がフォームに入っている(画像以外)
      expect(
        find('#item_name').value
      ).to eq @item1.name
      expect(
        find('#item_info').value
      ).to eq @item1.info
      expect(
        find('#item_category_id').value
      ).to eq "#{@item1.category_id}"
      expect(
        find('#item_sales_status_id').value
      ).to eq "#{@item1.sales_status_id}"
      expect(
        find('#item_shipping_fee_status_id').value
      ).to eq "#{@item1.shipping_fee_status_id}"
      expect(
        find('#item_prefecture_id').value
      ).to eq "#{@item1.prefecture_id}"
      expect(
        find('#item_scheduled_delivery_id').value
      ).to eq "#{@item1.scheduled_delivery_id}"
      expect(
        find('#item_price').value
      ).to eq "#{@item1.price}"
      # 投稿内容を編集する
      fill_in 'item[name]', with: ""
      # 編集してもItemモデルのカウントは変わらない
      expect{
        find('input[name="commit"]').click
      }.to change { Item.count }.by(0)
      # 編集ページへ戻される
      expect(page).to have_content('商品の情報を入力')
      # エラーメッセージのクラスが出現する
      expect(page).to have_css "div.error-alert" 
    end
    it 'ログインしていない状態で商品編集ページへアクセスすると、ログインページへ遷移すること' do
      # ログインせずにURLを直打ち
      visit edit_item_path(@item1)
      # ログイン画面へ遷移する
      expect(page).to have_content("会員情報入力")
      # エラーメッセージが出現している
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
    it '自身の出品した商品以外の商品編集ページへアクセスすると、トップページへ遷移すること' do
      visit new_user_session_path
      fill_in 'user[email]', with: @item1.user.email
      fill_in 'user[password]', with: @item1.user.password
      find('input[name="commit"]').click
      expect(current_path).to eq root_path
      find(:xpath, "//a[@href='/items/#{@item2.id}']").click
      # アイテム2に「購入画面に進む」ボタンがある
      expect(page).to have_link '購入画面に進む', href: item_transactions_path(@item2)
      # アイテム2に「商品の編集」の文字はない
      expect(page).to have_no_content '商品の編集'
      # 他人の出品した商品編集ページのURLを直打ち
      visit edit_item_path(@item2)
      # トップページへ戻される
      visit root_path
    end
  end
end