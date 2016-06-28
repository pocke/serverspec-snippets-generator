require 'json'
require 'active_support'
require 'active_support/core_ext'

info = JSON.parse(File.read(File.expand_path('../../autoload/serverspec_info.json', __FILE__)))

def variables_template(var_name)
  %!<variable name="#{var_name}" expression="" defaultValue="" alwaysStopAt="true" />!
end

CONTEXT = <<-CODE.chop
<context>
  <option name="RUBY" value="true" />
</context>
CODE


def resource_template(name, body)
  var = variables_template('TARGET_NAME')
  puts <<-CODE
<template name="#{name}" value="#{body.gsub("\n", '&#10;')}" description="#{name}" toReformat="true" toShortenFQNames="true">
#{var.indent(2)}
#{CONTEXT.indent(2)}
</template>
  CODE
end


def matcher_template(resource, name, info)
  if info['parameters'].present?
    v = info['parameters'].map{|x| "$#{x}$"}.join(", ")
    args = "(#{v})"
  end

  # TODO
  if info['chains'].present?
    chain = info['chains'].map{|x| ".#{x}($#{x}$)"}.join
  end

  vars = (info['parameters'] + info['chains']).map{|v| variables_template(v)}.join("\n")

  body = <<-CODE
it { should #{name}#{args}#{chain} }
  CODE


  <<-CODE
<template name="#{resource}_#{name}" value="#{body.gsub("\n", '&#10;')}" description="#{name} of #{resource}" toReformat="true" toShortenFQNames="true">
#{vars.indent(2)}
#{CONTEXT.indent(2)}
</template>
  CODE
end


def its_template(resource, name)
  pure_name = name[1..-1]
  body = <<-CODE
its(#{name}) { should be $END$ }
  CODE

  <<-CODE
<template name="#{resource}_#{pure_name}" value="#{body.gsub("\n", '&#10;')}" description="#{name} of #{resource}" toReformat="true" toShortenFQNames="true">
#{CONTEXT.indent(2)}
</template>
  CODE
end



puts '<templateSet group="Serverspec">'


# Resources
info.each_key do |res|
  puts resource_template res, <<-CODE
describe #{res}('$TARGET_NAME$') do
  $END$
end
  CODE
end


# matchers
info.each do |res, val|
  val['matchers'].each do |matcher_name, matcher_info|
    puts matcher_template(res, matcher_name, matcher_info)
  end

  val['its_targets'].each do |name|
    puts its_template(res, name)
  end
end

puts '</templateSet>'
