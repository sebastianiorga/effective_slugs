# Effective Slugs

Generates a URL-appropriate slug, as required, when saving a record.

Also overrides ActiveRecord .find() methods to accept the slug, or an id as the parameter.

Rails >= 3.2.x, Ruby >= 1.9.x.  Has not been tested/developed for Rails4.


## Getting Started

Add to Gemfile:

```ruby
gem 'effective_slugs'
```

Run the bundle command to install it:

```console
bundle install
```

(optional) If you want control over any excluded slugs, run the generator:

```console
rails generate effective_slugs:install
```

The generator will install an initializer which describes all configuration options.


## Usage

Add the mixin to an existing model:

```ruby
class Post
  acts_as_sluggable
end
```

Then create a migration to add the :slug column to the model.
As we're doing lookups on this column, a database index makes a lot of sense too:

```console
rails generate migration add_slug_to_post slug:string:index
```

which will create a migration something like

```ruby
class AddSlugToPost < ActiveRecord::Migration
  def change
    add_column :posts, :slug, :string
    add_index :posts, :slug
  end
end
```

## Behavior

### Slug Generation

When saving a record that does not have a slug, a slug will be automatically generated and assigned.

Tweak the behavior by adding the following instance method to the model:

```ruby
def should_generate_new_slug?
  slug.blank?
end
```

The slug is generated based on the slug_source instance method, which can also be overridden by adding the following instance method to the model:

```ruby
def slug_source
  return title if self.respond_to?(:title)
  return name if self.respond_to?(:name)
  to_s
end
```

There is also the idea of excluded slugs.  Every model in a rails application has its default route automatically excluded.
So if you have a model called Event, with its corresponding 'events' table, the /events slug will be unavailable.

You can add additional excluded slugs in the generated config file.

Any slug conflicts will be resolved by appending a -1, -2, etc to the slug.

### Finder Methods

```ruby
post = Post.create(:title => 'My First Post')
post.id
  => 1
post.slug
  => 'my-first-post'
```

The .find() ActiveRecord method is overridden so the following are equivelant:

```ruby
Post.find('my-first-post')
Post.find(1)
Post.where(:slug => 'my-first-post').first
```

## License

MIT License.  Copyright Code and Effect Inc. http://www.codeandeffect.com

You are not granted rights or licenses to the trademarks of Code and Effect

## Credits

Some of the code in this gem was inspired by an old version of FriendlyId (https://github.com/FriendlyId/friendly_id)

### Testing

The test suite for this gem is unfortunately not yet complete.

Run tests by:

```ruby
rake spec
```
