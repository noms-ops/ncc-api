#!/usr/bin/env rspec
# -*- mode: ruby -*-

$LOAD_PATH.unshift 'test/lib'
require 'rubygems'
require 'noms/cmdb'
require 'ncc_spec_helper'
require 'ncc'

Fog.mock!
NOMS::CMDB.mock!

describe NCC do
    before(:all) { setup_fixture }
    after(:all) { cleanup_fixture }

    before :all do
        $logger = LogCatcher.new
        $ncc = NCC.new('test/data/etc')
    end

    describe "#api_url" do

        context "with no configured v2api" do
            specify { $ncc.api_url.should == 'http://localhost/ncc_api/v2' }
        end

        context "with configured v2api" do

            it "returns configured v2api" do
                $ncc.config['services']['v2api'] = 'http://api.host/ncc_api/v2'
                $ncc.api_url.should == 'http://api.host/ncc_api/v2'
            end

        end

    end

end

describe NCC::Instance do
    before(:all) { setup_fixture }
    after(:all) { cleanup_fixture }

    describe ".new" do

        it "sets console_log" do
            instance = NCC::Instance.new($ncc, 'console_log' => 'testvalue')
            instance.console_log.should == 'testvalue'
        end

    end

    describe "#set_without_validation" do

        it "sets console_log" do
            instance = NCC::Instance.new($ncc)
            instance.set_without_validation(:console_log => 'testvalue')
            instance.console_log.should == 'testvalue'
        end

    end

    describe "#console_log=" do

        it "sets console_log" do
            instance = NCC::Instance.new($ncc)
            instance.console_log = 'testvalue'
            instance.console_log.should == 'testvalue'
        end

    end


end

describe NCC::Connection do
    before(:all) { setup_fixture }
    after(:all) { cleanup_fixture }

    before :all do
        $req = { 'size' => 'm1.medium', 'image' => 'centos5.6' }
        $ncc.clouds('awscloud').
            fog.register_image('testimg', 'testimg', '/dev/sda0')
        $ncc.config[:clouds]['awscloud']['images'] =
            { 'centos5.6' => $ncc.clouds('awscloud').fog.images.first.id }
    end

    context "in AWS" do

        before :each do
            $ncc.clouds('awscloud').fog.servers.each { |s| s.destroy }
            $instance = $ncc.clouds('awscloud').create_instance($req)
            $ncc.clouds('awscloud').fog.servers.get($instance.id).
                wait_for { ready? }
        end

        describe "#console_log" do

            it "returns the instance console log" do
                logtext = $ncc.clouds('awscloud').console_log($instance.id)
                logtext.should_not be_nil
            end

        end

    end

end
