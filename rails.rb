
投稿とユーザーを紐づける

各投稿に「どのユーザーがその投稿を作成したか」という情報を
持たせるために、postsテーブルにuser_idというカラムを用意します。

#「rails g migration add_user_id_to_posts
　→マイグレーションファイルを作成します。
#マイグレーションファイルの中身は、
add_column :posts,:user_id,:integer
#「rails db:migrate」を実行しましょう。

postsテーブルにuser_idカラムが追加できていることを
確認できたら、user_idにバリデーションを設定しましょう。
誰が投稿したか、という情報は必ずあるべきなので、
user_idに「presence: true」を指定します。
#validates :user_id, {presence: true}

########################################################################################################################3

新規投稿をログイン中のユーザー「@current_user.id」のものとする

def create
    @post = Post.new(
      content: params[:content],
      # user_idの値をログインしているユーザーのidにしてください
      user_id: @current_user.id
    )

####################################################################################################################

投稿にユーザー名やユーザー画像を表示する

user_idカラムの値から、そのユーザーの情報を取得する必要があります。
今回は投稿詳細ページなので、postsコントローラのshowアクション内で、
「@post.user_id」を用いて、そのidに該当するユーザーの情報を
データベースから取得しましょう。

#/controllers/posts_controller.rb

def show
    @post = Post.find_by(id: params[:id])
    @user = User.find_by(id: @post.user_id)
    
  end

#show.html.erb
<div class="post-user-name">
        <!-- ユーザーの画像が表示されるように、以下のsrcの中を埋めてください -->
        <img src="<%= "/user_images/#{@user.image_name}" %>">
        
        <!-- link_toメソッドを用いて、ユーザー詳細ページへのリンクを作成してください -->
        <%= link_to(@user.name,"/users/#{@user.id}")%>
      </div>

#############################################################################################################

Railsではモデル内にインスタンスメソッドを定義することができます。

インスタンスメソッド
クラスの中で定義し、インスタンスに対して呼び出すメソッドのこと

Postモデル内にその投稿に紐付いたuserインスタンスを戻り値として返すuserメソッドを定義しましょう。

#/models/post.rb
# インスタンスメソッドuserを定義してください
def user
    return User.find_by(id: self.user_id)
  end

#=============================================selfの使い方====================================================
  class Article < ActiveRecord::Base
    def hoge       #インスタンスメソッド
    end
  
    def self.hoge  #クラスメソッド
    end
  
    def pdf       #インスタンスメソッド
      self.hoge        #インスタンスメソッドのhogeが呼ばれる
      hoge             #インスタンスメソッドのhogeが呼ばれる
      self.class.hoge  #こうするとクラスメソッドのhogeを呼べる
    end
  
    def self.pdf  #クラスメソッド
      self.hoge        #クラスメソッドのhogeが呼ばれる
      hoge             #クラスメソッドのhogeが呼ばれる
    end
  end


===============================================================================================================




#rails consoleで以下のコマンドを実行してください
post = Post.find_by(id: 1)
post.user #←Postモデル内にその投稿に紐付いたuserインスタンスを戻り値として返すuserメソッド
quit

####################################################################################################################

Post モデルに定義した user メソッドを用いて、投稿詳細ページのコードを書き換えてみる

def show
    @post = Post.find_by(id: params[:id])
    # 以下の１行を、userメソッドを用いて書き換えてください
    @user = @post.user
  end

###################################################################################################################

投稿一覧ページでも、それぞれの投稿に紐付いているユーザ名や画像を表示してみよう。
投稿詳細ページと同じように、user メソッドを用いる.


<div class="post-user-name">
            <%= link_to(post.user.name, "/users/#{post.user.id}") %>
          </div>

link_toメソッドは、
第１引数： ユーザー名
第２引数： ユーザー詳細のURL
となるようにしてください。
#############################################################################################################

ユーザー詳細ページにそのユーザーが作成した投稿を一覧で表示する

Post.find_by(user_id:@user.id)
→find_by メソッドではその条件に合致するデータを「1件だけ」取得することができる

whereメソッド
複数のデータを取得する。
データを取得した場合、それぞれのデータは配列に入っています。

#rails consoleで以下のコマンドを実行してください
posts = Post.where(user_id: 1) #user_id:が1のデータをすべて取得
posts[0].content
quit

これを利用して、ユーザーに紐付く投稿をまとめて取得する「posts メソッド」を User モデルに定義する

#/models/user.rb
# インスタンスメソッドpostsを定義してください
def posts
    return Post.where(user_id:self.id)
  end

#################################################################################################################

 User モデルに定義した posts メソッドを用いて、ユーザー詳細ページにそのユーザーが作成した投稿を一覧で表示する

 @user.postsを用いて、各投稿をそれぞれ表示しましょう。
whereメソッドで取得した値は配列に入っていますので、
ビュー側でeach文を用いて、1つずつ投稿を表示していきます。
#<% @user.posts.each do |post| %>

################################################################################################################

投稿者のみに編集・削除リンクを表示しよう

「@post.user」のidと、「@current_user」のidを比較し、
等しい場合にのみ編集・削除リンクを表示しています。

<% if @post.user_id == @current_user.id%>
        <div class="post-menus">
          <%= link_to("編集", "/posts/#{@post.id}/edit") %>
          <%= link_to("削除", "/posts/#{@post.id}/destroy", {method: "post"}) %>
        </div>
#      <% end %>

#####################################################################################################################

今のままでは URL に直接アクセスすれば、編集・削除ができてしまう

今回は、投稿に紐づくユーザーと現在ログインしているユーザーが異なる
かどうかを比べるために、postsコントローラ内に「ensure_correct_user」
というメソッドを用意します。
before_actionを用いることで、このメソッドをedit、update、destroyの
それぞれのアクションで適用しましょう。

#/posts_controller.rb
before_action :ensure_correct_user, {only:[:edit, :update, :destroy]}

def ensure_correct_user
    @post = Post.find_by(id: params[:id])
    
    if @post.user_id != @current_user.id  #投稿を作成したユーザーとログインしているユーザーが一致する場合
    flash[:notice] = "権限がありません"
    redirect_to("/posts/index")
    end
  
end








