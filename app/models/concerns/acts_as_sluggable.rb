# ActsAsSluggable
#
# This module automatically generates slugs based on the :title, :name, or :to_s field
# using a before_validation filter
#
# Mark your model with 'acts_as_sluggable'
#
# and create the migration
#
# structure do
#   slug     :string
# end
#
# You can override
# ActsAsSluggable
#
# This module automatically generates slugs based on the :title, :name, or :to_s field
# using a before_validation filter
#
# Mark your model with 'acts_as_sluggable'
#
# and create the migration
#
# structure do
#   slug     :string
# end
#
# You can override
# def should_generate_new_slug?
#   new_record?
# end
#
# and
# def slug_source
#   return title if self.respond_to?(:title)
#   return name if self.respond_to?(:name)
#   to_s
# end
#
# This will work transparently with the ActsAsSiteSpecific, and should "just work"
# Please do not put any unique indexes on the slugs column. Or make it unique [:slug, :site_id]

module ActsAsSluggable
  extend ActiveSupport::Concern

  module ActiveRecord
    def acts_as_sluggable(options = {})
      if self.methods.include?(:is_site_specific) # ActsAsSiteSpecific
        @acts_as_sluggable_opts = {:validation_scope => :site_id}.merge(options)
      else
        @acts_as_sluggable_opts = {}.merge(options)
      end

      include ::ActsAsSluggable
    end
  end

  included do
    before_validation :set_slug, :if => proc { should_generate_new_slug? }
    before_validation :clean_slug
    validates_presence_of :slug
    validates_exclusion_of :slug, :in => EffectiveSlugs.all_excluded_slugs
    validates_format_of :slug, :with => /\A[a-zA-Z0-9_\-]*\z/, :message => 'only _ and - symbols allowed'

    if @acts_as_sluggable_opts[:validation_scope]
      validates_uniqueness_of :slug, :scope => @acts_as_sluggable_opts[:validation_scope]
    else
      validates_uniqueness_of :slug
    end
  end

  def set_slug
    raise StandardError, "ActsAsSluggable expected a table column :slug to exist" unless self.respond_to?(:slug)

    new_slug = slug_source.to_s.try(:parameterize)

    if new_slug.present?
      while EffectiveSlugs.excluded_slugs.include?(new_slug) do
        new_slug << "-" << self.class.name.demodulize.parameterize
      end

      # TODO: Could make this a bit smarter about conflicts
      num_slugs = self.class.name.constantize.where(:slug => new_slug).count
      num_slugs = self.class.name.constantize.where("#{self.class.table_name}.slug LIKE ?", "#{new_slug}%").count if num_slugs > 0

      num_slugs == 0 ? self.slug = new_slug : self.slug = "#{new_slug}-#{num_slugs}"
    end

    true
  end

  def clean_slug
    self.slug = slug.gsub(/^\/*/, '').gsub(/\/*$/, '')
  end

  def slug_source
    return title if self.respond_to?(:title)
    return name if self.respond_to?(:name)
    to_s
  end

  def should_generate_new_slug?
    slug.blank?
  end

  def to_param
    (slug.present? rescue false) ? slug_was : super
  end

  module ClassMethods
    def relation
      super.tap { |relation| relation.extend(FinderMethods) }
    end

    def find(*args)
      regular_find?(args) ? super : clean_find_by_slug(args)
    end

    def exists?(*args)
      regular_find?(args) ? super : (clean_find_by_slug(args).present? rescue false)
    end

    private

    def clean_find_by_slug(args)
      find_by_slug Array(args).map { |e| e.to_s.gsub(/^\/*/, '').gsub(/\/*$/, '') }
    end

    def regular_find?(args)
      args.first.is_a?(Array) || args.first.to_i > 0
    end
  end

  module FinderMethods
    def find(*args)
      regular_find?(args) ? super : clean_find_by_slug(args)
    end

    def exists?(*args)
      regular_find?(args) ? super : (clean_find_by_slug(args).present? rescue false)
    end

    private

    def regular_find?(args)
      args.first.is_a?(Array) || args.first.to_i > 0
    end

    def clean_find_by_slug(args)
      find_by_slug Array(args).map { |e| e.to_s.gsub(/^\/*/, '').gsub(/\/*$/, '') }
    end
  end


end

