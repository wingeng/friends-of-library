require 'json'

Camping.goes :Nuts

module Nuts::Controllers
  class Page < R '/fol.css'
    def get
      @headers['Content-Type'] = 'text/css'
      @headers['X-Sendfile'] = "#{Dir.pwd}/fol.css"
    end
  end

  class Doo < R '/Doo'
    def get
      "elll"
    end
  end

  class Index < R '/'
    def do_isbn
      @output = ""
      @title = "Not found"
      @isbn = @input.fetch("isbn", "")
      @price = 
      @price_f = 0.0
      @cutoff = @input.fetch("collections_cutoff", "20").to_i
      @detail_page = ""

      if (@input.has_key?("isbn")) then
        
        lup = `cd ..;./isbn-lookup.rb --api-mode #{@input.isbn} --insert`
        
        @output = JSON.parse(lup)
        @title = @output[:title]
        @price = @output.fetch("price", "$0.00")
        @price_f = @price.gsub("$", "").to_f
        @detail_page = @output.fetch("detail-page", "")
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
                document.f1.isbn.focus();
                setTimeout(focus_on_isbn, 2000);
            }
          }
        end

        link :rel => "stylesheet", :type => "text/css", :href => "fol.css"
      end
      body :onload => "focus_on_isbn()" do
        self << yield 
      end

    end
  end

  def isbnlook
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
            span :class => "output", :id => "output-title"  do @output["title"]  end
          end

          p do
            span :class => "output", :id => "output-price"  do @output["price"]  end
          end

          p do 
            if (@price_f >= @cutoff.to_f)
              div :id => "specials" do "To Specials" end
            end
          end

          p do 
            a :href => @detail_page do "amazon" end
          end

          #      div do @input end
        end
      end
    end
  end
end
