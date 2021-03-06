#!/usr/bin/env rspec
# -*- mode: ruby -*-

require 'ncc_spec_helper'
require 'ncc/config'
require 'fileutils'

describe NCC::Config do

    context "initializing" do

        before(:all) { setup_fixture }

        after(:all)  { cleanup_fixture }

        it "creates a NCC::Config object" do
            ncc = NCC::Config.new('test/data/etc')
            ncc.should be_an_instance_of NCC::Config
        end

        it "is current" do
            set_testvalue('testvalue0')
            ncc = NCC::Config.new('test/data/etc/test.conf')
            expect(ncc.current?).to be_truthy
        end

        it "raises an ArgumentError when config doesn't exist" do
            lambda do
                NCC::Config.new('nonexistent')
            end.should raise_error ArgumentError
        end

        it "parses a single file" do
            set_testvalue('testvalue0')
            ncc = NCC::Config.new('test/data/etc/test.conf')
            ncc.should have_key 'testkey'
            ncc['testkey'].should == 'testvalue0'
        end

    end

    context "accessing file-based config" do

        before(:all) { setup_fixture }

        after(:all)  { setup_fixture }

        before :each do
            set_testvalue('testvalue0')
            $logger = LogCatcher.new
            $ncc = NCC::Config.new('test/data/etc/test.conf',
                               :logger => $logger)
        end

        it "produces a hash" do
            $ncc.to_hash.should be_an_instance_of Hash
        end

        it "produces a hash with all the keys" do
            $ncc.to_hash.should have_key 'testkey'
        end


        it "updates when the file changes" do
            sleep 2
            set_testvalue('testvalue1')
            $ncc['testkey'].should == 'testvalue1'
        end

        it "doesn't update when within staleness_threshold" do
            ncc = NCC::Config.new('test/data/etc/test.conf',
                              :staleness_threshold => 4)
            sleep 2
            set_testvalue('testvalue1')
            ncc['testkey'].should == 'testvalue0'
            sleep 3
            ncc['testkey'].should == 'testvalue1'
        end

        it "warns when file goes bad" do
            sleep 2
            File.open('test/data/etc/test.conf', 'w') do |fh|
                fh << "bad json"
            end

            $ncc['testkey'].should == 'testvalue0'
            $logger['warn'][0].should match /not updating/
        end

        it "empties config if file goes away" do
            sleep 2
            FileUtils.rm 'test/data/etc/test.conf'
            $ncc.should_not have_key 'testkey'
        end

    end

    context "accessing directory-based config" do

        before(:all) { setup_fixture }

        after(:all)  { cleanup_fixture }

        before :each do
            set_testvalue 'testvalue0'
            FileUtils.mkdir 'test/data/etc/testdir'
            $logger = LogCatcher.new
            $ncc = NCC::Config.new('test/data/etc',
                               :logger => $logger)
        end

        after :each do
            FileUtils.rm_r 'test/data/etc/testdir' if
                File.exist? 'test/data/etc/testdir'
            FileUtils.rm 'test/data/etc/test.conf' if
                File.exist? 'test/data/etc/test.conf'
            FileUtils.rm 'test/data/etc/test2.conf' if
                File.exist? 'test/data/etc/test2.conf'
        end

        it "creates a key for a file in the directory" do
            $ncc.should have_key 'test'
        end

        it "stores a file-based config at the key named for the file" do
            $ncc['test'].should have_key 'testkey'
            $ncc['test']['testkey'].should == 'testvalue0'
        end

        it "deletes a file-based config when the file goes away" do
            sleep 2
            FileUtils.rm 'test/data/etc/test.conf'
            $ncc.should_not have_key 'test'
        end

        it "adds a file-based config when a new file shows up" do
            sleep 2
            set_testvalue('testvalue1', 'test2')
            $ncc.should have_key 'test2'
            $ncc['test2'].should be_an_instance_of NCC::Config
        end

        it "doesn't regenerate file-based subconfiguration" do
            nccsub = $ncc['test']
            sleep 2
            set_testvalue('testvalue1', 'test2')
            $ncc['test2'].should have_key 'testkey'
            $ncc['test'].object_id.should == nccsub.object_id
        end

        it "stores a directory-based configuration for subdirectories" do
            $ncc.should have_key :testdir
        end

        it "adds a file-based config when a new directory shows up" do
            $ncc.should_not have_key :testdir2
            sleep 2
            FileUtils.mkdir('test/data/etc/testdir2')
            $ncc.should have_key :testdir2
        end

        it "deletes a directory-based config when the directory goes away" do
            sleep 2
            FileUtils.rmdir 'test/data/etc/testdir'
            $ncc.should_not have_key :testdir
        end

        it "produces a hash slice" do
            h = $ncc.to_hash(:clouds, 'services')
            expect(h.keys.size).to eq 2
            expect(h).to have_key :clouds
            expect(h).to have_key 'services'
            expect(h).to_not have_key 'testkey'
        end

    end

    context "storing" do
        before(:all) { setup_fixture }
        after(:all)  { cleanup_fixture }

        before :each do
            set_testvalue 'testvalue0'
            FileUtils.mkdir 'test/data/etc/testdir'
            $logger = LogCatcher.new
            $ncc = NCC::Config.new('test/data/etc',
                               :logger => $logger)
        end

        after :each do
            FileUtils.rm_r 'test/data/etc/testdir'
        end

        it "stores a value" do
            $ncc['key'] = 'value'
            $ncc['key'].should == 'value'
        end

        it "deletes a value" do
            $ncc['key'] = 'value'
            $ncc.delete('key').should == 'value'
            $ncc['key'].should be_nil
        end
    end

end
