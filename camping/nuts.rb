require 'json'

Camping.goes :Nuts

module Nuts::Controllers
  class AllCSS < R /\/([a-z0-9_-]+.css)/
    def get(path)
      @headers['Content-Type'] = 'text/css'
      @headers['X-Sendfile'] = "#{Dir.pwd}/#{path}"
    end
  end
  class AllImages < R /\/([a-z0-9_-]+.jpg)/
    def get(path)
      @headers['Content-Type'] = 'image/jpeg'
      @headers['X-Sendfile'] = "#{Dir.pwd}/#{path}"
    end
  end
  class AllHtml < R /\/([a-z0-9_-]+.html)/
    def get(path)
      @headers['Content-Type'] = 'text/html'
      @headers['X-Sendfile'] = "#{Dir.pwd}/#{path}"
    end
  end

  class SimpleList < R '/simple-list'
    def get
      s = "<pre>"
      s += `cd ..;./simple-list.rb`
      s += "</pre>"
      s
    end
  end


  class MediaList < R '/media-list'
    def do_media_list
      @style_sheet = "fol2.css"
      lup = `cd ..;./isbn-list-in-media.rb`
      @output = JSON.parse(lup)

      render :media_list
    end

    def get
      do_media_list
    end

    #
    # Return the isbn to delete
    #
    def get_delete
      @input.each {|k, v|
        return k if v == "delete"
      }
      return nil
    end

    def post
      @email_list = @input.fetch("Email", "") != ""
      @clear_list = @input.fetch("Clear", "") != ""
      @isbn = @input.fetch("isbn", "").gsub(/[^0-9]/, "")


      @delete_value = get_delete

      if @email_list then
        @status_message = `cd ../smtp;./send_mail.rb`
      elsif @clear_list then
        @status_message = "List cleared: "
        
        `cd ..;./clear-media-list.rb all`
      elsif @delete_value then
        @status_message = "Deleted: " + @delete_value
        `cd ..;./clear-media-list.rb #{@delete_value}`
      elsif @simple_list then
        
      else
        # Add ISBN to media list
        @status_message = " to fol: " + @isbn
        lup =  `cd ..;./isbn-insert.rb isbn.db #{@isbn} true`

        @output = JSON.parse(lup)

        if @output.fetch("return-code", "false") == "false" then
          @status_message = "Item not found - " + @isbn
        else
          @status_message = "ISBN added: " + @isbn
        end
      end

      do_media_list
    end
  end

  class Index < R '/'
    def do_isbn
      @style_sheet = "fol.css"
      @output = ""
      @title = "Not found"
      @isbn = @input.fetch("isbn", "").gsub(/[^0-9]/, "")
      @price = 
        @price_f = 0.0
      @cutoff = @input.fetch("collections_cutoff", "20").to_i
      @detail_page = ""

      @bk_price = @bk_price_f = 0.0
      @bk_output = ""
      @bk_detail_page = ""

      if (@input.has_key?("isbn")) then
        lup =  `cd ..;./isbn-insert.rb isbn.db #{@isbn}`

        @output = JSON.parse(lup)
        if @output.fetch("return-code", "false") == "false" then
          @title = "Item not found - " + @isbn
        else
          @title = @output.fetch("title", "")
          @price = @output.fetch("price", "$0.00")
          @price_f = @price.gsub("$", "").to_f
          @detail_page = @output.fetch("detail-page", "")
        end

        if @price_f == 0.0 then
          # Bookfinder prices
          lup = `cd ..;./isbn-bookfinder #{@isbn}`
          @bk_output = JSON.parse(lup)
          if @bk_output.fetch("return-code", "false") == "true" then
            @bk_price = @bk_output.fetch("price", "$0.00")
            @bk_price_f = @bk_price.gsub("$", "").to_f
            @bk_detail_page = @bk_output.fetch("detail-page", "")
          end
        end

      end

      render :isbnlook
    end

    def get
      do_isbn
    end

    def post
      do_isbn
    end
  end

end

module Nuts::Views
  def layout
    html do
      head do
        title "ISBN Looker"
        script :language => "Javascript" do
          %Q{
            function fill_example() {
                var el = document.getElementById("isbn-text")
                if (el) el.value = "0765329042"

            }
            function focus_on_isbn() {
                var el = document.getElementById("isbn-text")
                el.focus()
                setTimeout(focus_on_isbn, 2000);
            }
            function clear_list_really() {
                if (confirm("Really clear the list?")) {
                   return true;
                }
                event.preventDefault();
                return false;
            }
          }
        end

        link :rel => "stylesheet", :type => "text/css", :href => @style_sheet
      end
      body :onload => "focus_on_isbn()" do
        self << yield 
      end

    end
  end

  def media_list
    div :class => "tool-bar" do
      a :class => "tool-bar", :href => "/" do "Scanner" end
      a :class => "tool-bar", :href => "/media-list" do "Media-List" end
      a :class => "tool-bar", :href => "/simple-list" do "Simple-List" end
      a :class => "tool-bar", :href => "http://fol.bok-choi.com:4567/media-list.html" do "Alpha" end
    end

    div :id => "outersection" do
      form :name => "media-list", :method => "post" do
        table :id => "media-list", :cellspacing => "0" do
          tr do
            td :class => "header" do
              span "ISBN: "
              input :type => "text", :name => "isbn", :id => "isbn-text"
              input :type => "submit", :value => "Find", :name => "Find"
            end
            td :class => "header", :width => "80%" do
              input :type => "submit", :value => "clear-list", :name => "Clear", :onClick => "clear_list_really()"
              input :type => "submit", :value => "e-mail", :name => "Email"
            end
          end
          tr do
            td :id => "header-line", :colSpan => "2" do
              div :id => "not-found" do
                @status_message
              end
            end
          end
          x = 1
          @output.each {|rec|
            classname = if x & 1 == 1 then "row-odd" else "row-even" end
            tr :class => classname do
              td :class => "title", :width => "80%" do
                span rec["title"]
              end
              td :class => "delete-button", :align => "center" do 
                input :type => "submit", :value => "delete", :name => rec["isbn"]
              end
            end
            x = x + 1
          }

        end
      end
    end
  end

  def isbnlook
    div :class => "tool-bar" do
      a :class => "tool-bar", :href => "http://fol.bok-choi.com:4567/media-list.html" do "Alpha" end
    end

    div :id => "outersection" do
      form :name =>"f1", :method => "post" do
        div :id => "isbn" do
          span "ISBN: "
          input :type => "text", :name => "isbn", :id => "isbn-text", :value => @isbn
          span :id => "find" do
            input :type => "submit", :value => "Find"
          end
          #          input :type => "button",  :value => "Example", :onclick => "fill_example()"

          span "Special Collections Price Cut Off: "
          
          select :name => "collections_cutoff" do
            (5 .. 75).step(5).each { |x|
              selected = ""
              selected = "foo" if (x == @input["collections_cutoff"])

              if (@cutoff == x)
                option :value => "#{x}", :selected => "true" do "$#{x}.00" end
              else
                option :value => "#{x}"  do "$#{x}.00" end
              end
            }
          end
        end
      end

      div :id => "imageandcontent" do
        div :id => "imagesection"  do
          img :src => @output["image-url"]
        end

        div :id => "contentsection" do
          p do
            span :class => "output", :id => "output-title"  do @title  end
          end

          p do
            span :class => "output", :id => "output-price"  do
              @output["price"] 
            end
            
            span :id => "to-affiliate" do
              a :href => @detail_page do "amazon" end
            end
          end

          if @bk_price_f > 0.0 then
            p do
              span :class => "output", :id => "output-price" do
                @bk_output["price"]
              end

              span :id => "to-affiliate" do
                a :href => @bk_detail_page do "bookfinder" end
              end
            end
          end

          p do 
            if (@price_f >= @cutoff.to_f || @bk_price_f >= @cutoff.to_f)
              div :id => "specials" do "To Specials" end
            end
          end

        end
      end
    end
  end
end
