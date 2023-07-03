---
layout: post
author: teteteo619
title: システムスペックを実装する
date: 2023-07-03
thumbnail: /assets/img/posts/hello.jpg
category: Rspec
summary: 今回は、下記の項目に対してシステムスペックを実装します。システムスペックとは、アプリケーションのプログラム全体が期待通りの挙動になっているかを確認するための統合テストです。
keywords:
permalink: /blog/systemspec
---

下記の統合テストを行います。

- ログイン成功/失敗
- ログアウトできる
- ユーザー登録成功/失敗
- フォローできること
- フォローをはずせること
- 投稿一覧が閲覧できる
- 新規投稿できる
- 自分の投稿に編集・削除ボタンが表示される
- 他人の投稿には編集・削除ボタンが表示されない
- 投稿を更新できる
- 投稿を削除できる
- 投稿の詳細画面が閲覧できる
- 投稿に対していいねできる
- 投稿に対していいねを外せる

## システムスペックを使うための準備
&nbsp; システムスペックでは、ChromeとChromeDriverをローカルにインストールする必要があります。ChromeDriverは、Chrome操作を自動化するのに必要です。

```zsh
$brew install chromedriver
```

また、chromeはバージョン変化が激しいため元々導入されている方も予め最新版にアップデートすることをお勧めします。

```zsh
$brew upgrade chromedriver
```

railsでchromedriverを使うためにgemのwebdriversを導入します。また、導入されていなければテスト自動化ソフトウェアであるcapybaraとテストフレームワークであるrspec-railsも入れちゃってください！

Gemfile
```Gemfile
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
end
```

設定ファイルに以下も追加してください。

spec/rails_helper.rb
```rb
require 'rspec/rails'
require 'factory_bot'
require 'capybara/rspec'

RSpec.configure do |config|
    #FactoryBot.createなどのFactoryBotの部分を省略することができる
    config.include FactoryBot::Syntax::Methods 
end

```


rspecは以下のコマンドで生成されます。

```zsh
$rails g rspec:install
```


## システムスペックをheadlessに設定する
&nbsp; システムスペックはデフォルトでテスト実行するとブラウザが立ち上がりシュミレートを実行します。今回はテストが通っていることが確認できればいいので、シュミレートをオフにします。まずは、rspecのsupportフォルダ下が読み込まれるように設定を加えます。デフォルトで記述されているのでコメントを外してあげてください。

spec/rails_helper.rb
```rb
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }
```

ヘッドレスに設定するため設定用のファイルを追加します。以下のように記述して下さい。

spec/support/driver_setting.rb
```rb
RSpec.configure do |config|
  config.before(:each, type: :system) do
    # Spec実行時、ブラウザが自動で立ち上がり挙動を確認できる
    # driven_by(:selenium_chrome)

    # Spec実行時、ブラウザOFF
    driven_by(:selenium_chrome_headless)
  end
end
```

これでヘッドレスに設定できているはずです。(以下は別のアプリで実装済みものを試しています。)
[![Image from Gyazo](https://i.gyazo.com/5f61df4f9300414a611b99a3036e875f.gif)](https://gyazo.com/5f61df4f9300414a611b99a3036e875f)

## ログイン・ログアウトのシステムスペック実装
&nbsp; まずはuserのデータが必要なのでfactorybotを設定します。factorybotのデフォルト値は、各カラムの値が全てランダム値となるように設定すると良いらしい。その上で必要な値のみ明示的にして「このテストで重要な値は何か」がわかりやすくなるから。今回は、Fakerを用いてランダムなデータを生成していきます。

spec/factories/users.rb
```rb
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { 'password' }
    password_confirmation { 'password' }
  end
end
```

<br>

ログイン・ログアウトのシステムスペックを実装していきます。sessionのrspecのファイルを生成しましょう！

```zsh
$rails g rspec:system session
```

下記はログインページのviewです。

app/views/sessions/new.html.slim

```slim
main
  .login-register-form
    .login-register-form-inner
      .card.mb-3
        = form_with url: login_path, class: 'card-body session_login', local: true do |f|
          .form-group
              = f.label :email, ' メールアドレス', class: 'bmd-label-floating'
              = f.text_field :email, class: 'form-control'
          .form-group
              = f.label :password, 'パスワード　', class: 'bmd-label-floating'
              = f.password_field :password, class: 'form-control'
          = f.submit 'ログイン', class: 'btn btn-raised btn-primary', id: 'login'
      .card
          .card-body
            | アカウントをお持ちでないですか？
            = link_to  "登録する", new_user_path
```

ログイン・ログアウトのシステムスペックは以下のように実装しました。

sessions_spec.rb
```rb
require 'rails_helper'

RSpec.describe "Sessions", type: :system do
  let(:user) { create(:user) }

  describe 'ログイン' do
    context '認証情報が正しい場合' do
      it 'ログインできること' do
        visit '/login'
        fill_in 'メールアドレス', with: user.email
        fill_in 'パスワード', with: 'password'
        within '.session_login' do
          click_on 'ログイン'
        end
        expect(current_path).to eq root_path
        expect(page).to have_content 'ログインしました'
      end
    end

    context '認証情報が誤りがある場合' do
      it 'ログインできないこと' do
        visit '/login'
        fill_in 'メールアドレス', with: user.email
        fill_in 'パスワード', with: 'misspassword'
        within '.session_login' do
          click_on 'ログイン'
        end
        expect(current_path).to eq login_path
        expect(page).to have_content 'ログインに失敗しました'
      end
    end
  end

  describe 'ログアウト' do
    it 'ユーザーがログアウト後ログイン画面にリダイレクトされること' do
      login(user)
      click_on 'ログアウト'
      expect(current_path).to eq '/login'
      expect(page).to have_content 'ログアウトしました'
    end
  end
end
```


テストが通るか下記のコマンドで実行してみると、、、
```zsh
&bin/rspec spec/system/sessions_spec.rb
```

見事通りました！

<a href="https://gyazo.com/4c8c00a08363072f84f110c2cf49d133"><img src="https://i.gyazo.com/4c8c00a08363072f84f110c2cf49d133.png" alt="Image from Gyazo" width="643"/></a>

## ユーザー登録、フォローのシステムスペック実装
&nbsp; まずは、いちいちログインのプロセスをテストに書くのはめんどくさいのでログイン用のモジュールを作成します。supportフォルダ下に以下のファイルを作成します。

spec/support/login_support.rb
```rb
module LoginSupport
  def login(user)
    visit '/login'
    fill_in 'メールアドレス', with: user.email
    fill_in 'パスワード', with: 'password'
    click_on 'login'
  end
end
```

いかに設定を加えればlogin(user)を使うことができます。

rails_helper.rb
```rb
config.include LoginSupport, type: :system
```


下記はユーザー登録のviewです。

app/views/users/new.html.slim
```slim
.login-register-form
  .login-register-form-inner
    .card.mb-3
      = form_with model: @user, class: 'card-body', local: true do |f|
        = render 'shared/error_messages', object: @user
        .form-group
          = f.label :name, class: 'bmd-label-floating'
          = f.text_field :name, class: 'form-control'
        .form-group
          = f.label :email, class: 'bmd-label-floating'
          = f.text_field :email, class: 'form-control'
        .form-group
          = f.label :password, class: 'bmd-label-floating'
          = f.password_field :password, class: 'form-control'
        .form-group
          = f.label :password_confirmation, class: 'bmd-label-floating'
          = f.password_field :password_confirmation, class: 'form-control'
        = f.submit '登録', class: 'btn btn-raised btn-primary'
    .card
      .card-body
        | アカウントをお持ちですか
        = link_to  "ログインする", login_path
```

<br>

対してユーザー登録のシステムスペックは以下の通りです。

```rb
require 'rails_helper'

RSpec.describe "Users", type: :system do

  describe 'ユーザー登録' do
    context 'ユーザー情報が正しい場合' do
      it 'ユーザー登録が成功すること' do
        visit '/users/new'
        within '.login-register-form' do
          fill_in 'ユーザー名', with: 'Rails太郎'
        end
        fill_in 'メールアドレス', with: 'rails@example.com'
        fill_in 'パスワード', with: '12345678'
        fill_in 'パスワード(確認)', with: '12345678'
        click_on '登録'
        expect(current_path).to eq root_path
        expect(page).to have_content('ユーザーの作成に成功しました')
      end
    end

    context 'ユーザー情報が誤りがある場合' do
      it 'ユーザー登録が失敗すること' do
        visit '/users/new'
        within '.login-register-form' do
          fill_in 'ユーザー名', with: ''
        end
        fill_in 'メールアドレス', with: ''
        fill_in 'パスワード', with: ''
        fill_in 'パスワード(確認)', with: ''
        click_on '登録'
        expect(page).to have_content('ユーザー名を入力してください')
        expect(page).to have_content('メールアドレスを入力してください')
        expect(page).to have_content('パスワードは3文字以上で入力してください')
        expect(page).to have_content('パスワード(確認)を入力してください')
        expect(page).to have_content('ユーザーの作成に失敗しました')
      end
    end
  end
  
  describe 'フォロー' do
    let!(:user) { create(:user) }
    let!(:other_user) { create(:user) }

    before do
      login(user)
    end

    it 'フォローができること' do
      visit root_path
      expect{
        within "#follow-area-#{other_user.id}" do
          click_on 'follow'
          expect(page).to have_css('#unfollow')
        end
      }.to change(user.follows, :count).by(1)
    end

    it 'フォローを外せること' do
      user.follow(other_user)
      visit root_path
      expect{
        within "#follow-area-#{other_user.id}" do
          click_on 'unfollow'
          expect(page).to have_css('#follow')
        end
      }.to change(user.follows, :count).by(-1)
    end
  end
end
  ```

<br>

テストを実行すると以下のように通りました！

[![Image from Gyazo](https://i.gyazo.com/3b04ad696ed7853d100619ee02068266.png)](https://gyazo.com/3b04ad696ed7853d100619ee02068266)

## 投稿のCRUD、いいねのシステムスペック実装
&nbsp; 最後に投稿関連のシステムスペックを実装していきます。まずは、postのfactorybotのデータを設定します。

spec/factories/post.rb
```rb
FactoryBot.define do
  factory :post do
    content { Faker::Lorem.word }
    #複数画像保存の際に、json形式で保存するため対応した([]に値を入れなければならない)
    images { [File.open("#{Rails.root}/spec/fixtures/dummy.jpeg")] }
    user
end
```

そしてテストは以下のように実装しました。viewは今回省略します。

posts_spec.rb
```rb
require 'rails_helper'

RSpec.describe "Posts", type: :system do
  let!(:user) { create(:user) }
  let!(:my_post) { create(:post, user: user) }
  let!(:other_post1) { create(:post) }
  let!(:other_post2) { create(:post) }

  describe 'ポスト一覧' do

    context 'ログインしている場合' do
      before do
        login(user)
        user.follow(other_post1.user)
      end
      it 'フォロワーと自分の投稿だけが閲覧できること' do
        visit root_path
        expect(page).to have_content other_post1.content
        expect(page).to have_content my_post.content
        expect(page).not_to have_content other_post2.content
      end
    end

    context 'ログインしていない場合' do
      it '全てのポストが表示されること' do
        visit posts_path
        expect(page).to have_content other_post1.content
        expect(page).to have_content my_post.content
        expect(page).to have_content other_post2.content
      end
    end
  end

  describe 'ポスト投稿' do
    it '画像を投稿できること' do
      login(user)
      visit new_post_path
      within '#posts_form' do
        attach_file '画像', "#{Rails.root}/spec/fixtures/dummy.jpeg"
        fill_in '本文', with: "test"
        click_on '登録する'
      end
      expect(page).to have_content '投稿しました'
      expect(page).to have_content 'test'
    end
  end


  describe 'ポスト更新' do
    before do
      login(user)
    end

    it '自分の投稿に編集ボタンが表示されること' do
      visit root_path
      within "#post-#{my_post.id}" do
        expect(page).to have_css '.edit-button'
      end
    end


    it '他人の投稿には編集ボタンが表示されないこと' do
      user.follow(other_post1.user)
      visit root_path
      within "#post-#{other_post1.id}" do
        expect(page).to_not have_css '.edit-button'
      end
    end


    it '投稿を更新できること' do
      visit edit_post_path(my_post)
      within '#posts_form' do
        attach_file '画像', "#{Rails.root}/spec/fixtures/dummy.jpeg"
        fill_in '本文', with: "update"
        click_on '登録する'
      end
      expect(page).to have_content('投稿を更新しました')
      expect(page).to have_content("update")
    end
  end

  describe '投稿を削除できること' do
    before do
      login(user)
    end

    it '自分の投稿に削除ボタンが表示されること' do
      visit root_path
      expect(page).to have_css '.delete-button'
    end

    it '他人の投稿には削除ボタンが表示されないこと' do
      user.follow(other_post1.user)
      visit root_path
      within "#post-#{other_post1.id}" do
        expect(page).to_not have_css '.delete-button'
      end
    end

    it '投稿を削除できること' do
      visit root_path
      within "#post-#{my_post.id}" do
        page.accept_confirm { find('.delete-button').click }
      end
      expect(page).to have_content("投稿を削除しました")
      expect(page).not_to have_content(my_post.content)
    end
  end

  describe 'ポスト詳細' do
    before do
      login(user)
    end

    it '投稿の詳細画面が閲覧できる' do
      visit post_path(my_post)
      expect(current_path).to eq "/posts/#{my_post.id}"
    end
  end

  describe 'いいね関連' do
    before do
      login(user)
      user.follow(other_post1.user)
    end

    it 'いいねができること' do
      visit root_path
      expect{
        within "#like_area-#{other_post1.id}" do
          find('.like-button').click
        end
        expect(page).to have_css '.unlike-button'
      }.to change(user.like_posts, :count).by(1)
    end

    it 'いいねを外せること' do
      user.like(other_post1)
      visit root_path
      expect{
        within "#like_area-#{other_post1.id}" do
          find('.unlike-button').click
        end
        expect(page).to have_css '.like-button'
      }.to change(user.like_posts, :count).by(-1)
    end
  end
end
```

<br>

テストを実行すると以下のように投稿関連のシステムスペックも通りました！

[![Image from Gyazo](https://i.gyazo.com/1814d020a74966abe79979c951e51bc2.png)](https://gyazo.com/1814d020a74966abe79979c951e51bc2)

これで各項目のテストが全て通りました！Rspec関連は、everyday rspecや伊藤淳一先生のQiitaの記事をリファレンスにすればそれなりには書けると思います。お疲れ様でした🙇‍


## 参考記事
- [【Rails】はじめてのSystemSpec(RSpec)](https://qiita.com/niwa1903/items/e1ad9ab39811aa1cf312)
- [RSpec スタイルガイド](https://github.com/willnet/rspec-style-guide)
