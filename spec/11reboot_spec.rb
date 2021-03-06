#!/usr/bin/env rspec
# -*- mode: ruby -*-

$LOAD_PATH.unshift 'test/lib'
require 'rubygems'
require 'ncc_spec_helper'
require 'noms/cmdb'
require 'ncc'

Fog.mock!
NOMS::CMDB.mock!

describe NCC::Connection do
    before(:all) { setup_fixture }
    after(:all) { cleanup_fixture }

    before :all do
        $logger = LogCatcher.new
        $ncc = NCC.new('test/data/etc')
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

        describe "#reboot" do

            it "reboots the instance" do
                expect($ncc.clouds('awscloud').reboot($instance.id)).to be_truthy
            end

        end

    end

end
