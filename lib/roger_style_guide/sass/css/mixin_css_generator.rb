module RogerStyleGuide::Sass::Css
  # Modifies a mixins hash to add css.
  class MixinCssGenerator
    def initialize(environment, prefix = "mixin")
      @environment = environment
      @prefix = prefix

      @_visitor = RogerStyleGuide::Sass::InfoVisitor.new(@environment)
    end

    def generate(mixins)
      mixins.each do |name, mixin|
        next if mixin[:has_params]

        mixin[:css] = mixin_css(name)
      end

      mixins
    end

    protected

    def mixin_css(name)
      # Generate a fictious rule
      rule = Sass::Tree::RuleNode.new([".#{@prefix}-#{name}"])
      rule.children << Sass::Tree::MixinNode.new(
        name, [], Sass::Util::NormalizedMap.new({}), nil, nil
      )
      rule.options = @environment.options

      # Visit rule so we can actually generate css afterwards
      rule = @_visitor.visit(rule)

      rule.css
    end
  end
end
