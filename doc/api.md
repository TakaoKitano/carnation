
Table of Contents
=================

  * [carnation server API reference](#carnation-server-api-reference)
    * [1 OAuth2 アクセストークン取得](#1-oauth2-%E3%82%A2%E3%82%AF%E3%82%BB%E3%82%B9%E3%83%88%E3%83%BC%E3%82%AF%E3%83%B3%E5%8F%96%E5%BE%97)
      * [1.1 Authentication header](#11-authentication-header)
      * [1.2 get user token](#12-get-user-token)
      * [1.3 get viewer token](#13-get-viewer-token)
    * [2 user management](#2-user-management)
      * [2.1 create new user](#21-create-new-user)
      * [2.2 change user attribute](#22-change-user-attribute)
      * [2.3 delete user](#23-delete-user)
      * [2.4 get user info](#24-get-user-info)
      * [2.5 get user id by email](#25-get-user-id-by-email)
    * [3 item management](#3-item-management)
      * [3.1 initiate item upload](#31-initiate-item-upload)
      * [3.2 notify upload completed](#32-notify-upload-completed)
      * [3.3 delete item](#33-delete-item)
      * [3.4 undelete item](#34-undelete-item)
    * [4 get item](#4-get-item)
      * [4.1 get single item](#41-get-single-item)
      * [4.2 get items](#42-get-items)
    * [5 events](#5-events)
      * [5.1 get user events](#51-get-user-events)
      * [5.2 tell the server item(s) are read](#52-tell-the-server-items-are-read)
      * [5.3 tell the server item(s) are unread](#53-tell-the-server-items-are-unread)
      * [5.4 tell the server item(s) are retrieved](#54-tell-the-server-items-are-retrieved)
    * [6 device registration](#6-device-registration)
      * [6.1 register device to receive push notifications](#61-register-device-to-receive-push-notifications)
      * [6.2 get the list of registered devices](#62-get-the-list-of-registered-devices)
      * [6.3 delete device registration](#63-delete-device-registration)
      * [6.4 send a message to a registered device](#64-send-a-message-to-a-registered-device)
    * [7 viewer API](#7-viewer-api)
      * [7.1 retrieve users that can be accessed by viewer](#71-retrieve-users-that-can-be-accessed-by-viewer)
      * [7.2 post viewer likes item](#72-post-viewer-likes-item)
      * [7.3 get viewer info](#73-get-viewer-info)
    * [8 file upload](#8-file-upload)
      * [8.1 get upload url for HTTP put](#81-get-upload-url-for-http-put)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)
# carnation server API reference

## 1 OAuth2 アクセストークン取得

carnation API の呼び出しを行うためには、OAuth2 access token が必要です.
[RFC6749 The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)


carnation server では、カメラアプリからの呼び出しに用いる token を user token, STB viewer からのAPI呼び出しに用いる token を viewer token と呼んでいます.

user token は [RFC6749 Client Password](https://tools.ietf.org/html/rfc6749#section-2.3.1) の方式で取得します. 

viewer token は、[RFC6479 Client Credentials Grant](https://tools.ietf.org/html/rfc6749#section-4.4) の方式で取得します.


現状の実装では、Access Token は、24時間で無効になります.
```
   self.expires_at = now + 1 * (3600 * 24)  # 1 days for now
```
無効になった場合は、再取得もしくは refresh token が必要です.
なお refresh token を行うことができるのは、user token のみです.
viewer token の取得に際しては、パスワード入力などのユーザーインタラクションがないので、必要に応じてトークンを単に再取得すれば良いという考え方です.

取得したトークンは、全ての carnation server API を呼び出す際に、Request Header に次のように設定する必要があります. [RFC6750 The OAuth 2.0 Authorization Framework: Bearer Token Usage](https://tools.ietf.org/html/rfc6750)

```
Authorization:Bearer a233dc78b84983da434344235a65fc84
```

### 1.1 Authentication header 

user token, viewer token どちらもの取得のときも、[RFC2617] (https://tools.ietf.org/html/rfc2617) で規定されている Basic Authentication header を設定する必要があります.
RFC2617 で用いられている Authentication header に設定する userid, password はそれぞれ carnation server の内部的な値(というか呼び方) では次のものに相当します.


| rfc2617       | carnation     |
|---------------|---------------|
| userid        | appid         |
| password      | secret        |


すなわち、carnation server に対して、access token の取得リクエストを発行するためには、運営者よりあらかじめ配布された appid, secret のペアが必要となります. 
carnation server は広く一般に開放されたサービスを提供するのではなくて、appid, secret のペアを保有している限られたクライアントからのアクセスを受け付けるという仕組みになっています.

### 1.2 get user token

| method        | end point     |
|---------------|---------------|
| PUT           | /token        |

Authentication header にセットする appid, secret はサービス運営者からアサインされるもので、アプリケーションのタイプやバージョンごとに異なるものを持つことができます（共通でも構わない）.
そのアプリケーションが carnation server にアクセスする権限を持つかどうか carnation server が判断するためのものです.
アプリケーション開発者が 個別のアプリケーションに搭載します.

**parameters**

新規取得

| name        |  value             |  mandatory? | default value  |
|-------------|--------------------|-------------|----------------|
| grant_type  |  "password"        |    yes     | N/A            |
| username    |  ユーザーの email  |    yes     | N/A            |
| password    |  ユーザーパスワード|    yes     | N/A            |

refresh_token

| name          |  value             |  mandatory? | default value  |
|---------------|--------------------|-------------|----------------|
| grant_type    |  "refresh_token"   |    yes      | N/A            |
| refresh_token |  refresh token     |    yes      | N/A            |

**output**

| name          |  value          | 
|---------------|-----------------|
| access_token  |  user token |
| refresh_token |  refresh token      | 
| token_type    |  "bearer"       |
| user_id       | user id |
| expires_in    | expire するまでの秒|
| scope         | スコープ文字列（現状使われてない)|

**example**

```
{
  "access_token":"7fb0b857382671892b77f5d4048589b0",
  "refresh_token":"9d9fba1cb49c124b817c1dfe4ed9307a",
  "token_type":"bearer",
  "user_id":4,
  "expires_in":86400,
  "scope":"read create delete"
}
```

### 1.3 get viewer token

| method        | end point     |
|---------------|---------------|
| PUT           | /token    |

Authentication header にセットする appid, secret は、それぞれのSTBで独自な値を持ちます.
STBの出荷時になんらかの手段で端末に搭載されます.


**parameters**

| name          |  value                |  mandatory?   | default value  |
|---------------|-----------------------|---------------|----------------|
| grant_type    |  "client_credential"  |    yes        | N/A            |

**output**

| name          |  value          | 
|---------------|-----------------|
| access_token  |  user token |
| token_type    |  "bearer"       |
| user_id       | view id |
| expires_in    | expire するまでの秒|
| scope         | スコープ文字列（現状使われてない)|

**example**
```
{
  "access_token":"8d69445035b989dfd50f467d5aab5afa",
  "token_type":"bearer",
  "viewer_id":1,
  "expires_in":86400,
  "scope":"read like"
}
```

## 2 user management

### 2.1 create new user


| method        | end point     | required token   |
|---------------|---------------|------------------|
| POST          | /api/v1/user  | signup |

ユーザーを作成します.
この API を呼び出すためには、admin もしくは signup の権限が必要です.
なお現状のこの APIの実装は簡易実装なので今後改良が必要です.


**parameters**

| name          |  value          |  mandatory?   | default value  |
|---------------|-----------------|---------------|----------------|
| email         |  メールアドレス |    yes        | N/A            |
| password      |  パスワード     |    yes        | N/A            |

**output**

| name          |  value          | 
|---------------|-----------------|
| id         |  user_id |
| email      |  user email      | 
| name      |  user name (メールアドレスから適当に生成される)     |
| password      |  パスワード     | 

**error**

| code    |  message                        | description |
|---------|---------------------------------|---------------------------|
| 400     |  access denied                  | 権限がない|
| 400     |  invalid parameter  email       | emailが指定されてない|
| 400     |  invalid parameter  password    | password が指定されてない|
| 400     |  sepcified email already exists | 同じ email のユーザーが既にある|

**example**

```
{
  "id": 7,
  "email": "testtest@chikaku.co.jp",
  "name": "testtest_chikaku.co.jp",
  "password": "abc"
}
```

### 2.2 change user attribute

| method        | end point     | required token |
|---------------|---------------|----------------|
| POST          | /api/v1/attributes  | user(of user_id)|

ユーザーの email, name, password を変更します
この API を呼び出すためには、admin もしくは user_id のユーザーであることが必要です.
パラメータで指定したもののみが指定した値に変更されます.

**parameters**

| name          |  value              |  mandatory?   | default value  |
|---------------|---------------------|---------------|----------------|
| user_id       |  user id            |   yes         | N/A            |
| email         |  user email address |    no         | N/A            |
| name          |  user name          |    no         | N/A            |
| password      |  user password      |    no         | N/A            |

**output**

| name          |  value          | 
|---------------|-----------------|
| id         |  user_id |
| email      |  user email      | 
| name      |  user name |
| password      |  user password |

**error**

| code    |  message                        | description |
|---------|---------------------------------|---------------------------|
| 400     |  access denied                  | 権限がない |
| 400     |  token invalid                  | access token 不正   |
| 400     |  no such user                   | user_id 不正 |

**example**

```
{
  "id": 4,
  "email": "test01@chikaku.com",
  "name": "harahara",
  "password": ""
}
```

### 2.3 delete user

| method        | end point     | required token |
|---------------|---------------|----------------|
| DELETE        | /api/v1/user  | admin |

ユーザーを削除します
この API を呼び出すためには、admin 権限が必要です.
user を削除しても S3 storage のファイルは削除されません.(未実装です)

**parameters**

| name          |  value          |  mandatory?   | default value  |
|---------------|-----------------|---------------|----------------|
| user_id       |  user id        |   yes         | N/A            |

**output**

| name      |  value          | 
|-----------|-----------------|
| id        |  user_id        |
| email     |  user email     | 
| name      |  user name      |

**error**

| code    |  message                        | description |
|---------|---------------------------------|---------------------------|
| 400     |  access denied                  | 権限がない |
| 400     |  user not found                 | user_id 不正 |

**example**

```
{
  "id": 4,
  "email": "test01@chikaku.com",
  "name": "harahara",
}
```

### 2.4 get user info

| method        | end point     | required token   |
|---------------|---------------|------------------|
| GET           | /api/v1/user  | user(of user_id) |

ユーザー情報を取得します

**parameters**

| name          |  value        | mandatory? | default value  |
|---------------|---------------|------------|----------------|
| user_id       |  user id      |  yes       | N/A            |

**output**

| name                |  value          | 
|---------------------|-----------------|
| id                  |  user_id        |
| email               |  user email     | 
| name                |  user name      |
| role                |  admin:1, default:2, signup:3, 通常:100|
| status              |  1 (固定)       |
| timezone            |  timezone(数値) |
| viewers             | このユーザーが所有している viewerの 一覧（配列） |
| groups              |  このユーザーが所有している group の一覧（配列） |
| belong_to_groups    |  このユーザーが所属しているグループの一覧（配列）|

**error**

| code    |  message                        | description |
|---------|---------------------------------|---------------------------|
| 400     |  access denied                  | token 不正、権限がない |
| 404     |  user not found                 | user_id 不正 |

**example**

```
{
  "id": 4,
  "email": "test01@chikaku.com",
  "name": "harahara",
  "role": 100,
  "status": 1,
  "timezone": 9,
  "viewers": [
    {
      "id": 1,
      "name": "test01viewer",
      "status": 1,
      "user_id": 4,
      "client_id": 5,
      "phone_number": null,
      "postal_code": null,
      "address": null,
      "valid_through": 1444636922,
      "created_at": 1413100922,
      "timezone": 9,
      "credentials": {
        "id": 5,
        "appid": "6052d5885f9c2a12c09ef90f815225d3",
        "secret": "f6af879a7db8bfbe183e08c1a68e9035",
        "created_at": 1413100922
      }
    }
  ],
  "groups": [
    {
      "id": 1,
      "name": "test01group",
      "description": null,
      "user_id": 4,
      "created_at": 1413100922
    }
  ],
  "belong_to_groups": [
    {
      "id": 1,
      "name": "test01group",
      "description": null,
      "user_id": 4,
      "created_at": 1413100922
    }
  ]
}
```

### 2.5 get user id by email

| method        | end point              | required token |
|---------------|------------------------|---------------|
| GET           | /api/v1/user_by_email  | user,viewer   |

指定された email を持つユーザーの id を検索します

**parameters**

| name          |  value        | mandatory? | default value  |
|---------------|---------------|------------|----------------|
| email         |  user email   |  yes       | N/A            |

**output**

| name                |  value          | 
|---------------------|-----------------|
| user_id             |  user id        |

**error**

| code    |  message                        | description |
|---------|---------------------------------|---------------------------|
| 404     |  user not found                 | 指定された email の userは無い |

**example**
```
{
  "user_id": 4
}
```

## 3 item management

**アイテムアップロードの流れ**

<a href="upload_sequence.svg">
<img src="upload_sequence.png" alt="upload_sequence"/>
</a>

1. カメラアプリより、/api/v1/initiate を呼んでアップロードを開始します
2. carnation server から database へアクセスして、新規アイテムを生成します
3. カメラアプリへ、item_id, item_url を返します
4. カメラアプリは、アイテム（画像・動画）のファイルを item_url を使って S3 へアップロードします
5. カメラアプリは アップロードの結果：HTTP PUT method のレスポンスを確認します
6. カメラアプリは carnation server にアップロード完了を通知します (/api/v1/activate)
7. carnation server は redis の queue に item_id を追加します
8. カメラアプリへ activate の結果を通知します.この時点ではまだ派生ファイルは生成されてません. item のstatus は、0(initiate) となります

**派生ファイル生成の流れ**

上記のアップロードの流れとはまったく独立に、非同期に動いている派生ファイル生成用のプロセスが resque というモジュールを使って動いています.
この resque process は、負荷状況に応じて複数のプロセスを複数のマシン上で起動しておくことが可能です。

<a href="create_derivatives.svg">
<img src="create_derivatives.png" alt="create_derivatives"/>
</a>

1. resque process は定期的に新規の item_id を redis queue へ問い合わせます. もし上記アイテムアップロードにより、新規 item_id が登録されている場合は、その item_id を返します
2. resque process は s3 storage よりアップロードされたオリジナルのファイルを取得します
3. thumbnail image, 動画スクリーンショットなど、派生ファイルを生成します
4. 生成した派生ファイルを S3 へアップロードします
5. item のステータスを 0(initiate) から 1(active) へ変更します

### 3.1 initiate item upload

| method        | end point              | required token |
|---------------|------------------------|----------------|
| POST          | /api/v1/item/initiate  | user           |

アイテムアップロードを開始します.

**parameters**

| name        |  value                     | mandatory? | default value  |
|-------------|----------------------------|------------|----------------|
| user_id     |  user id                   |  yes       | N/A            |
| item_id     |  item id                   |  no        | N/A            |
| file_hash   |  item id                   |  no        | ""             |
| file_info   |  text                      |  no        | ""             |
| timezone    |  timezone number e.g. 9    |  no        |user's timezone |
| shot_at     |  [unix time](http://en.wikipedia.org/wiki/Unix_time) | no | initiate した日時|
| title       |  text                      |  no        | ""             |
| description |  text                      |  no        | ""             |
| extension   | ".jpg",".png",".mp4",".mov"| yes        | N/A            |

- fish_hash はファイルの sha1sum を16進表記した文字列です. Unix系OSの sha1sum コマンドの出力と同じです. 同一のファイルが既にアップロード済みかどうかを、file_hash を比較することで検出します.
```
$ echo -n "hello" | sha1sum
aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d
```
- file_info はアプリで自由に設定する文字列です たとえばアプリのローカルなファイルのパス情報などを入れることを想定しています
- timezone を指定しない場合は user の timezone が使われます
- 動画ファイルなど 撮影日時がファイルの exif情報として取得できない場合は、shot_at を指定して明示的に撮影日時を設定してください. shot_at を指定しなくて、かつファイルの exif 情報がない場合は、shot_at は initiate を呼び出した日時が設定されます.


**output**

| name                |  value          | 
|---------------------|-----------------|
| item_id             |  item id        |
| status              |  item status(0) |
| url                 |  url to put     |

- カメラアプリは取得した url を用いて HTTP PUT メソッドによりファイルのアップロードを行います.
- アップロードが完了したら、次項の /api/v1/item/activte を呼び出します.

- url は 28800秒(8時間）有効です.
- 期限が切れる前にアップロードを完了させる必要があります.
-もし期限が切れてしまった場合など、再度 url を取得する必要がある場合は、item_id を指定して initiate を呼び出します。


**error**

| code    |  message                        | description |
|---------|---------------------------------|---------------------------|
| 400     |  user_id invalid                | user_id 不正 |
| 400     |  invalid token                | access token 不正 |
| 400     |  access denied                  | 権限不足 |
| 400     |  item_id invalid                | item_id が指定されているが該当する itemがない|
| 400     |  extension required             | extension が指定されていない |
| 400     |  extension invalid              | extension の値が不正|
| 400     |  file_hash conflict             | 同じfile_hash を持つ item が既にある|

**example**

```
{
  "item_id": 118,
  "status": 0,
  "url": "https://carnationdev.s3-ap-northeast-1.amazonaws.com/00000004/00000118.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI2ZSXBHOXAWRFCQA%2F20150412%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20150412T042537Z&X-Amz-Expires=28800&X-Amz-Signature=6e1e5abea772aa7f5421398bf2652117fac9297115c5190a8bc65b175bc31c83&X-Amz-SignedHeaders=Host"
}
```

### 3.2 notify upload completed

| method        | end point              | required token |
|---------------|------------------------|----------------|
| PUT           | /api/v1/item/activate  | user           |

アイテムアップロード完了を通知します.
この呼び出しにより、派生ファイル生成のプロセスが生成されます

**parameters**

| name        |  value                     | mandatory? | default value  |
|-------------|----------------------------|------------|----------------|
| item_id     |  item id                   |  yes       | N/A            |
| valid_after |  秒数                      |  no        | 0              |

- /api/v1/item/initiate で取得した item_id を指定します
- valid_after では、そのアイテムが何秒後に viewer からアクセス可能になるかを指定します. デフォルトでは 0 (即座にアクセス可能になる) です. ただし即座といっても、派生ファイル生成が非同期に動いている関係上、サムネールなど含めてアクセス可能になるには数分以上程度は待つ必要があります.


**output**

| name                |  value          | 
|---------------------|-----------------|
| id                  |  item id        |
| status              |  item status(0) |


- この時点では status は常に 0(initiated) です

**error**

| code    |  message                        | description |
|---------|---------------------------------|---------------------------|
| 400     |  invalid token                | access token 不正 |
| 400     |  access denied                  | 権限不足 |
| 400     |  item not found                | item_id が指定されているが該当する itemがない|

**example**

```
{
  "id": 118,
  "status": 0
}
```

### 3.3 delete item

| method        | end point              | required token |
|---------------|------------------------|----------------|
| DELETE        | /api/v1/item           | user           |

itemを削除します.
item activate の前によばれた場合、すなわち item status が 0(initiated) のときには、アイテムのレコードを完全に削除します.
そうでない場合は item.status が 2(deleted) 状態になりますが、データとしては削除されません

アイテムが削除されてもS3上のファイルは削除されません.

**parameters**

| name        |  value                     | mandatory? | default value  |
|-------------|----------------------------|------------|----------------|
| item_id     |  item id                   |  yes       | N/A            |


**output**

| name                |  value          | 
|---------------------|-----------------|
| id                  |  item id        |
| status              |  item status    |

status の値

- item.status:0(initiated) の時：0 (itemは完全に削除された）
- item.status:1(active) の時 : 2 (item は undelete 可能)
- item.status:2(deleted) の時 : 2 (item は undelete 可能)

**error**

| code    |  message                        | description |
|---------|---------------------------------|---------------------------|
| 400     |  invalid token                | access token 不正 |
| 400     |  access denied                 | 権限不足 |
| 400     |  item_id_ invalid                | item_id が指定されているが該当する itemがない|

**example**

```
{
  "id": 118,
  "status": 0
}
```

### 3.4 undelete item

| method        | end point              | required token |
|---------------|------------------------|----------------|
| PUT           | /api/v1/item/undelete  | user           |

削除状態(status=2)の item を復活させます.
すなわち status=1 にします.

**parameters**

| name        |  value                     | mandatory? | default value  |
|-------------|----------------------------|------------|----------------|
| item_id     |  item id                   |  yes       | N/A            |


**output**

| name                |  value          | 
|---------------------|-----------------|
| id                  |  item id        |
| status              |  item status    |

status の値

- item.status:0(initiated) の時：0 (initiated)
- item.status:1(active) の時 : 1 (active)
- item.status:2(deleted) の時 : 1 (active)

**error**

| code    |  message                        | description |
|---------|---------------------------------|---------------------------|
| 400     |  invalid token                | access token 不正 |
| 400     |  access denied                 | 権限不足 |
| 400     |  item_id_ invalid                | item_id が指定されているが該当する itemがない|

**example**

```
{
  "id": 118,
  "status": 1
}
```

## 4 get item

### 4.1 get single item

| method        | end point              | required token |
|---------------|------------------------|----------------|
| GET           | /api/v1/item           | user, viewer   |

アイテム情報を取得します.
このAPIの呼び出しを行うためには指定する item を所有するuser と同じグループに所属している必要があります.

**parameters**

| name        |  value                     | mandatory? | default value  |
|-------------|----------------------------|------------|----------------|
| item_id     |  item id                   |  yes       | N/A            |


**output**

| name                |  value          | 
|---------------------|-----------------|
| id                  |  item id        |
| user_id             |  user id        |
| path                |  s3 上の path   |
| extension           |  ".jpg", ".png", ".mp4", ".mov"|
| status              |  item status    |
| title               |  item title     |
| description         |  item description |
| width         |  item original file width |
| height         |  item original file height |
| filesize       | file size in bytes|
| valid_after   | unix time: item がviewerから閲覧可能になる日時 |
| created_at     | unix time: item record の生成日時 |
| updated_at     | unix time: item 更新日時|
| mime_type      | "image/jpeg" など |
| file_hash      | ファイルのsha1sum 16進表記 文字列 |
| file_info      | アプリが設定した文字列 |
| timezone       | timezone |
| shot_at        | unix time: 撮影日時 |
| rotation       | 表示の際に回転が必要な角度 0, 90, 180, 270 のどれか|
| url       | url  |
| liked_by       | like されている状況 （配列)|
| derivatives       | 派生ファイル(配列)|

- url には有効時間があります. 現状の実装では 28800秒（8時間）です

**like_by**

| name                |  value          | 
|---------------------|-----------------|
|viewer_id            | viewer id       |
|count                | 1               |

**derivatives**

| name                |  value          | 
|---------------------|-----------------|
|item_id              | item_id         |
|index": 1,           | 1:medium size image, 2:thumbnail image |
|path                 | S3上での path (アプリでは使わない) |
|extension            |".jpg" |
|status               | item status  |
|name                 |index の値に対応する名前 "medium", "thumbnail"|
|width                |image width |
|height               |iamage height |
|duration             |動画の場合の再生時間秒|
|filesize             |ファイルサイズ|
|created_at           |レコード生成日時|
|mime_type            |"image/jpeg" |
|url                  |url |

- url には有効時間があります. 現状の実装では 28800秒（8時間）です


**error**

| code    |  message                        | description |
|---------|---------------------------------|---------------------------|
| 400     |  invalid token                | access token 不正 |
| 400     |  access denied                 | 権限不足 |
| 400     |  item not  dound                | item_id が指定されているが該当する itemがない|

**example**
```
{
  "id": 2,
  "user_id": 4,
  "path": "00000004/00000002",
  "extension": ".jpg",
  "status": 1,
  "title": "test image",
  "description": null,
  "width": 4032,
  "height": 3024,
  "duration": 0,
  "filesize": 5585186,
  "valid_after": 1428816619,
  "created_at": 1413100923,
  "updated_at": 1428816624,
  "mime_type": "image/jpeg",
  "file_hash": "e0b01d5e089489aca99f0871cd2a6a915c37449a",
  "file_info": null,
  "timezone": null,
  "shot_at": 1357262740,
  "rotation": 0,
  "url": "https://carnationdev.s3-ap-northeast-1.amazonaws.com/00000004/00000002.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI2ZSXBHOXAWRFCQA%2F20150412%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20150412T053041Z&X-Amz-Expires=28800&X-Amz-Signature=89cde108eef9e112f789193ea752e42dc550a1918c52af7dd2d8eb72e200c066&X-Amz-SignedHeaders=Host",
  "liked_by": [
    {
      "viewer_id": 1,
      "count": 1
    }
  ],
  "derivatives": [
    {
      "item_id": 2,
      "index": 1,
      "path": "00000004/00000002_01",
      "extension": ".jpg",
      "status": 1,
      "name": "medium",
      "width": 1440,
      "height": 1080,
      "duration": 0,
      "filesize": 915823,
      "created_at": 1413100922,
      "mime_type": "image/jpeg",
      "url": "https://carnationdev.s3-ap-northeast-1.amazonaws.com/00000004/00000002_01.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI2ZSXBHOXAWRFCQA%2F20150412%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20150412T053041Z&X-Amz-Expires=28800&X-Amz-Signature=6e5d7908e15559976775f9bdabb9ddd8fc5ed3894bc9fa3bdb0b564bf88213ff&X-Amz-SignedHeaders=Host"
    },
    {
      "item_id": 2,
      "index": 2,
      "path": "00000004/00000002_02",
      "extension": ".jpg",
      "status": 1,
      "name": "thumbnail",
      "width": 100,
      "height": 100,
      "duration": 0,
      "filesize": 46155,
      "created_at": 1413100922,
      "mime_type": "image/jpeg",
      "url": "https://carnationdev.s3-ap-northeast-1.amazonaws.com/00000004/00000002_02.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI2ZSXBHOXAWRFCQA%2F20150412%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20150412T053041Z&X-Amz-Expires=28800&X-Amz-Signature=be637952f4a5cf686dd1fc3fe2cccd462e534b4d8a129281f1d0ed82e3224d0c&X-Amz-SignedHeaders=Host"
    }
  ]
}
```

### 4.2 get items


| method        | end point              | required token |
|---------------|------------------------|----------------|
| GET           | /api/v1/user/items     | user, viewer   |

(複数の)アイテム情報を取得します.
このAPIの呼び出しを行うためには指定する user_id の user と同じグループに所属している必要があります.

**parameters**

| name        |  value               | mandatory? | default value  |
|-------------|----------------------|------------|----------------|
| user_id     |  user id             |  yes       | N/A            |
| item_id     |  item id             |  no        | N/A            |
| count       |  number              |  no        | 50             |
| greater_than|  number              |  no        | N/A            |
| less_than   |  number              |  no        | N/A            |
| created_after  |  unix time        |  no        | N/A            |
| created_before |  unix time        |  no        | N/A            |
| shot_after  |  unix time        |  no        | N/A            |
| shot_before |  unix time        |  no        | N/A            |
| updated_after  |  unix time        |  no        | N/A            |
| updated_before |  unix time        |  no        | N/A            |
| offset |  number        |  no        | 0|
| order |  'asc', 'desc'        |  no        | 'asc' (古いものから順に取得)|
| order_by |  'created_at', 'shot_at', 'updated_at'    |  no        | 'created_at' （生成日時)
| ignore_status |  true/false   |  no        | false|
| status |  0, 1, 2   |  no        | 1(active)|
| ignore_valid_after | true/false | no | false |
| no_details | true/false | no | false |
| output | full/compact/minimum/summary | no | full|

- count の最大値は1000です.(output=fullで1000だとかなり時間がかかるので注意)
- greater_than の対象は item_id です. 指定した場合、指定した id より大きな item_id のみを取得します.
- less_than の対象は item_id です.指定した場合、指定した id より小さな item_id のみを取得します.
- ignore_status:falseのときは、item.status:1 のもののみを取得します。item.status:0, item.status:2のアイテムは取得しません. 
- ignore_status:trueのときは、item.status にかかわらず全てのitemを取得します
- status を指定した場合、その状態のアイテムのみを取得します
- ignore_valid_after:true の場合、valid_afterの日時になっていないアイテムも取得します
- no_details:true の場合、id 情報のみが返されます (output=minimumと同じ)
- output を指定することで、返される情報の詳細加減を変えることができます

**output**

4.1 の output の項目を参照してください.

**error**

| code    |  message                        | description |
|---------|---------------------------------|---------------------------|
| 400     |  user_id invalid         | user_id が不正 |
| 400     |  no access grant                 | 権限不足 |

**example**

output=compact
```
{
  "user_id": 4,
  "count": 2,
  "items": [
    2,
    3
  ]
}
```

output=minimum
```
{
  "user_id": 4,
  "count": 2,
  "items": [
    {
      "id": 2
    },
    {
      "id": 3
    }
  ]
}
```

output=summary
```
{
  "user_id": 4,
  "count": 2,
  "items": [
    {
      "id": 2,
      "status": 1,
      "file_hash": "e0b01d5e089489aca99f0871cd2a6a915c37449a"
    },
    {
      "id": 3,
      "status": 1,
      "file_hash": "0b1aa485629ae85d182a2e61230010a9906cf8af"
    }
  ]
}
```

output=full(default)

```
{
  "user_id": 4,
  "count": 2,
  "items": [
    {
      "id": 2,
      "user_id": 4,
      "path": "00000004/00000002",
      "extension": ".jpg",
      "status": 1,
      "title": "test image",
      "description": null,
      "width": 4032,
      "height": 3024,
      "duration": 0,
      "filesize": 5585186,
      "valid_after": 1428816619,
      "created_at": 1413100923,
      "updated_at": 1428816624,
      "mime_type": "image/jpeg",
      "file_hash": "e0b01d5e089489aca99f0871cd2a6a915c37449a",
      "file_info": null,
      "timezone": null,
      "shot_at": 1357262740,
      "rotation": 0,
      "url": "https://carnationdev.s3-ap-northeast-1.amazonaws.com/00000004/00000002.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI2ZSXBHOXAWRFCQA%2F20150412%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20150412T053221Z&X-Amz-Expires=28800&X-Amz-Signature=3fd19f770246c43aaade0d9d06a8e55ec24d6ba0696b9b6ce8b3f1485dd1603b&X-Amz-SignedHeaders=Host",
      "liked_by": [
        {
          "viewer_id": 1,
          "count": 1
        }
      ],
      "derivatives": [
        {
          "item_id": 2,
          "index": 1,
          "path": "00000004/00000002_01",
          "extension": ".jpg",
          "status": 1,
          "name": "medium",
          "width": 1440,
          "height": 1080,
          "duration": 0,
          "filesize": 915823,
          "created_at": 1413100922,
          "mime_type": "image/jpeg",
          "url": "https://carnationdev.s3-ap-northeast-1.amazonaws.com/00000004/00000002_01.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI2ZSXBHOXAWRFCQA%2F20150412%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20150412T053221Z&X-Amz-Expires=28800&X-Amz-Signature=ee0045679ab70a78d95084252d681b0190bedf11eeb6dddda4d407eeff8cc9d9&X-Amz-SignedHeaders=Host"
        },
        {
          "item_id": 2,
          "index": 2,
          "path": "00000004/00000002_02",
          "extension": ".jpg",
          "status": 1,
          "name": "thumbnail",
          "width": 100,
          "height": 100,
          "duration": 0,
          "filesize": 46155,
          "created_at": 1413100922,
          "mime_type": "image/jpeg",
          "url": "https://carnationdev.s3-ap-northeast-1.amazonaws.com/00000004/00000002_02.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI2ZSXBHOXAWRFCQA%2F20150412%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20150412T053221Z&X-Amz-Expires=28800&X-Amz-Signature=a4ee71bb6d4eb535766c4a6f296976cef5d8e256ddfc8ecc5dbba51f18504990&X-Amz-SignedHeaders=Host"
        }
      ]
    },
    {
      "id": 3,
      "user_id": 4,
      "path": "00000004/00000003",
      "extension": ".jpg",
      "status": 1,
      "title": "test image",
      "description": null,
      "width": 4032,
      "height": 3024,
      "duration": 0,
      "filesize": 5665158,
      "valid_after": 1428816732,
      "created_at": 1413100924,
      "updated_at": 1428816738,
      "mime_type": "image/jpeg",
      "file_hash": "0b1aa485629ae85d182a2e61230010a9906cf8af",
      "file_info": null,
      "timezone": null,
      "shot_at": 1357262872,
      "rotation": 0,
      "url": "https://carnationdev.s3-ap-northeast-1.amazonaws.com/00000004/00000003.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI2ZSXBHOXAWRFCQA%2F20150412%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20150412T053221Z&X-Amz-Expires=28800&X-Amz-Signature=c5f5579aa33dbb3d87b3618e370d5e8493aa81459f410161737c33d0a2dc14dc&X-Amz-SignedHeaders=Host",
      "liked_by": [
        {
          "viewer_id": 1,
          "count": 1
        }
      ],
      "derivatives": [
        {
          "item_id": 3,
          "index": 1,
          "path": "00000004/00000003_01",
          "extension": ".jpg",
          "status": 1,
          "name": "medium",
          "width": 1440,
          "height": 1080,
          "duration": 0,
          "filesize": 877757,
          "created_at": 1413100922,
          "mime_type": "image/jpeg",
          "url": "https://carnationdev.s3-ap-northeast-1.amazonaws.com/00000004/00000003_01.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI2ZSXBHOXAWRFCQA%2F20150412%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20150412T053221Z&X-Amz-Expires=28800&X-Amz-Signature=f864322b8849eeb17ad505448a93532dfc406e3f5914e99c183cdfcedf4b49b9&X-Amz-SignedHeaders=Host"
        },
        {
          "item_id": 3,
          "index": 2,
          "path": "00000004/00000003_02",
          "extension": ".jpg",
          "status": 1,
          "name": "thumbnail",
          "width": 100,
          "height": 100,
          "duration": 0,
          "filesize": 46958,
          "created_at": 1413100922,
          "mime_type": "image/jpeg",
          "url": "https://carnationdev.s3-ap-northeast-1.amazonaws.com/00000004/00000003_02.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI2ZSXBHOXAWRFCQA%2F20150412%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20150412T053221Z&X-Amz-Expires=28800&X-Amz-Signature=2ac4234e987fce09ad08bb23e55b5fd3d693933a17970b5b938313fb0542ad14&X-Amz-SignedHeaders=Host"
        }
      ]
    }
  ]
}
```

## 5 events

### 5.1 get user events

**example**

```
{
  "user_id": 4,
  "new_count": 8,
  "max_retrieved_id": 0,
  "events": [
    {
      "id": 4,
      "created_at": 1413101574,
      "updated_at": 1413101773,
      "event_type": 1,
      "viewer_id": 1,
      "read": false,
      "retrieved": false,
      "viewer_name": "test01viewer",
      "item_ids": []
    },
    {
      "id": 5,
      "created_at": 1413101793,
      "updated_at": 13,
      "event_type": 1,
      "viewer_id": 1,
      "read": false,
      "retrieved": false,
      "viewer_name": "test01viewer",
      "item_ids": []
    },
    {
      "id": 6,
      "created_at": 1413101919,
      "updated_at": 1413099290,
      "event_type": 1,
      "viewer_id": 1,
      "read": false,
      "retrieved": false,
      "viewer_name": "test01viewer",
      "item_ids": []
    },
    {
      "id": 7,
      "created_at": 1413107013,
      "updated_at": 1413115504,
      "event_type": 1,
      "viewer_id": 1,
      "read": false,
      "retrieved": false,
      "viewer_name": "test01viewer",
      "item_ids": [
        2,
        3,
        4
      ]
    },
    {
      "id": 8,
      "created_at": 1413117602,
      "updated_at": 1413125320,
      "event_type": 1,
      "viewer_id": 1,
      "read": false,
      "retrieved": false,
      "viewer_name": "test01viewer",
      "item_ids": [
        4,
        5,
        6
      ]
    },
    {
      "id": 9,
      "created_at": 1413125510,
      "updated_at": 1413125553,
      "event_type": 1,
      "viewer_id": 1,
      "read": false,
      "retrieved": false,
      "viewer_name": "test01viewer",
      "item_ids": [
        2,
        3,
        4,
        5,
        6,
        7
      ]
    },
    {
      "id": 10,
      "created_at": 1413205416,
      "updated_at": 1413208743,
      "event_type": 1,
      "viewer_id": 1,
      "read": false,
      "retrieved": false,
      "viewer_name": "test01viewer",
      "item_ids": [
        2,
        4
      ]
    },
    {
      "id": 11,
      "created_at": 1419407735,
      "updated_at": 1419407736,
      "event_type": 1,
      "viewer_id": 1,
      "read": false,
      "retrieved": false,
      "viewer_name": "test01viewer",
      "item_ids": [
        4
      ]
    }
  ]
}
```

### 5.2 tell the server item(s) are read

**example**
```
{
  "user_id": 4,
  "event": [
    4,
    5,
    6
  ]
}
```

### 5.3 tell the server item(s) are unread

**example**
```
{
  "user_id": 4,
  "events": [
    4
  ]
}
```

### 5.4 tell the server item(s) are retrieved

## 6 device registration

### 6.1 register device to receive push notifications

### 6.2 get the list of registered devices

### 6.3 delete device registration

### 6.4 send a message to a registered device

## 7 viewer API

### 7.1 retrieve users that can be accessed by viewer

### 7.2 post viewer likes item

### 7.3 get viewer info

## 8 file upload

### 8.1 get upload url for HTTP put
