module Jekyll
  class CategoryPageGenerator < Generator
    safe true

    def generate(site)
      # Get all categories from posts
      categories = site.posts.docs.flat_map { |post| post.data["categories"] || [] }.uniq
      
      # Create a page for each category
      categories.each do |category|
        site.pages << CategoryPage.new(site, site.source, "categories", category)
      end
    end
  end

  # A Page that shows all posts for a specific category
  class CategoryPage < Page
    def initialize(site, base, dir, category)
      @site = site
      @base = base
      @dir = dir
      @name = "#{category.downcase.gsub(' ', '-')}.md"

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'category.html')
      
      self.data['title'] = category.capitalize
      self.data['category'] = category
      self.data['permalink'] = "/categories/#{category.downcase.gsub(' ', '-')}/"
    end
  end
end