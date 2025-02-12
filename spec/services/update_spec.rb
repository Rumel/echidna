# frozen_string_literal: true

require 'date'
require_relative '../../lib/echidna/services/update'

RSpec.describe 'UpdateService' do
  subject { Echidna::UpdateService.new }

  describe 'private methods'
  describe '#get_position' do
    describe 'when there are no items in the playlist' do
      let(:current_items) { [] }
      let(:selected_playlist) { double(order: 'title') }
      let(:item) { double(snippet: double(channel_title: 'test')) }

      it 'returns 0' do
        expect(subject.send(:get_position, selected_playlist, current_items, item)).to eq(0)
      end
    end

    describe 'when there are items in the playlist' do
      describe "when the playlist's order is 'title'" do
        let(:current_items) { [] }
        let(:selected_playlist) { double(order: 'title') }
        let(:baseball) { { channel_title: 'baseball', published_at: DateTime.new(2022, 10, 31, 9, 0, 0, '+0') } }
        let(:cats_one) { { channel_title: 'cats', published_at: DateTime.new(2022, 10, 31, 9, 0, 0, '+0') } }
        let(:cats_two) { { channel_title: 'cats', published_at: DateTime.new(2022, 10, 31, 10, 0, 0, '+0') } }
        let(:lemur) { { channel_title: 'lemurs', published_at: DateTime.new(2022, 10, 30, 9, 0, 0, '+0') } }

        describe "when the item's channel title is not in the playlist" do
          let(:videos) { [baseball, lemur] }

          describe 'and should come first' do
            let(:item) { double(snippet: double(channel_title: 'alligators')) }

            it do
              expect(subject.send(:get_position, selected_playlist, videos, item)).to eq(0)
            end
          end

          describe 'and should come in the middle' do
            let(:item) { double(snippet: double(channel_title: 'cats')) }

            it do
              expect(subject.send(:get_position, selected_playlist, videos, item)).to eq(1)
            end
          end

          describe 'and should come last' do
            let(:item) { double(snippet: double(channel_title: 'zebra')) }

            it do
              expect(subject.send(:get_position, selected_playlist, videos, item)).to eq(2)
            end
          end
        end

        describe "when the item's channel title is in the playlist" do
          let(:videos) { [baseball, cats_one, cats_two, lemur] }

          describe 'and should come first' do
            let(:item) { double(snippet: double(channel_title: 'cats', published_at: DateTime.new(2022, 10, 31, 8, 0, 0, '+0'))) }

            it do
              expect(subject.send(:get_position, selected_playlist, videos, item)).to eq(1)
            end
          end

          describe 'and should come in the middle' do
            let(:item) do
              double(snippet: double(channel_title: 'cats', published_at: DateTime.new(2022, 10, 31, 9, 30, 0, '+0')))
            end

            it do
              expect(subject.send(:get_position, selected_playlist, videos, item)).to eq(2)
            end
          end

          describe 'and should come last' do
            let(:item) do
              double(snippet: double(channel_title: 'cats', published_at: DateTime.new(2022, 10, 31, 10, 30, 0, '+0')))
            end

            it do
              expect(subject.send(:get_position, selected_playlist, videos, item)).to eq(3)
            end
          end
        end
      end

      describe "when the playlist's order is 'date'" do
        let(:selected_playlist) { double(order: 'date') }
        let(:first) { { channel_title: 'cats', published_at: DateTime.new(2022, 10, 31, 9, 0, 0, '+0') } }
        let(:second) { { channel_title: 'baseball', published_at: DateTime.new(2022, 10, 31, 10, 0, 0, '+0') } }
        let(:videos) { [first, second] }

        describe 'and the item should come first' do
          let(:item) { double(snippet: double(channel_title: 'cats', published_at: DateTime.new(2022, 10, 31, 8, 0, 0, '+0'))) }

          it do
            expect(subject.send(:get_position, selected_playlist, videos, item)).to eq(0)
          end
        end

        describe 'and the item should come in the middle' do
          let(:item) { double(snippet: double(channel_title: 'cats', published_at: DateTime.new(2022, 10, 31, 9, 30, 0, '+0'))) }

          it do
            expect(subject.send(:get_position, selected_playlist, videos, item)).to eq(1)
          end
        end

        describe 'and the item should come in last' do
          let(:item) { double(snippet: double(channel_title: 'cats', published_at: DateTime.new(2022, 10, 31, 10, 30, 0, '+0'))) }

          it do
            expect(subject.send(:get_position, selected_playlist, videos, item)).to eq(2)
          end
        end
      end
    end
  end
end
