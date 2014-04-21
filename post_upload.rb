
class PostUpload < Sinatra::Base
  configure :development do 
    Bundler.require :development 
    register Sinatra::Reloader 
  end 
  post '/api/v1/item/initiate_post' do
    p "initiate_post called"
    user_id = params[:user_id].to_i
    item_id = params[:item_id].to_i
    extension = params[:extension] 
    user = User.where(:id=>user_id).first 
    halt(400, "user_id invalid") if not user

    if item_id > 0 
      item = Item.where(:id=>item_id).first 
      halt(400, "item_id invalid") if not item
    else 
      halt(400, "extension required") if not extension
      halt(400, "extension invalid") if extension.index('.') != 0
      item = Item.new(:user_id=>user.id, :extension=>extension)
        item.status = Item::STATUS[:initiated]
        item.name = params[:name]
        item.width = params[:width].to_i
        item.height = params[:height].to_i 
        item.duration = params[:duration].to_i
        item.filesize = params[:filesize].to_i
      item.save
    end

    form = $bucket.presigned_post(:key => item.path+item.extension)
    html = "<html>\n<body>\n"
    html += "<form action=#{form.url} method='post' enctype='multipart/form-data'>\n"
    form.fields.map do |(name, value)|
      html += %(<input type="hidden" name="#{name}" value="#{value}" />\n)
    end
    html += <<-END
    <input type="file" name="file"/><br/>
    <p>"#{item.path+item.extension}"</p>
    <input type="submit" name="upload" value="upload"/>
    </form>
    </body></html>
    END
    html
  end
end
