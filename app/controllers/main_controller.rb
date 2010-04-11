class MainController < ApplicationController
  
  require 'pp'
  
  def test
    render :text => "ok"
  end
  
  def submit_job
    blanks = params.values.detect{|i|i.empty?}
    render :text => "fill in all fields!" and return false unless blanks.empty?
    render :text => "ok"
  end
  
end
