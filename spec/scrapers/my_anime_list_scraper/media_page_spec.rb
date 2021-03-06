require 'rails_helper'

RSpec.describe MyAnimeListScraper::MediaPage do
  include_context 'MAL CDN'
  describe '#titles' do
    before do
      stub_request(:get, %r{https://myanimelist.net/anime/.*})
        .to_return(fixture('scrapers/my_anime_list_scraper/anime_detail_movie.html'))
    end
    subject { described_class.new('https://myanimelist.net/anime/306/Your_Name') }

    it 'should return a hash with string keys' do
      expect(subject.titles).to be_a(Hash)
      expect(subject.titles.keys).to all(be_a(String))
    end

    it 'should return the romaji title as en_jp' do
      expect(subject.titles['en_jp']).to eq('Kimi no Na wa.')
    end

    it 'should return the english title as en_us' do
      expect(subject.titles['en_us']).to eq('Your Name.')
    end

    it 'should return the original kanji title as ja_jp' do
      expect(subject.titles['ja_jp']).to eq('君の名は。')
    end
  end

  describe '#poster_image' do
    before do
      stub_request(:get, %r{https://myanimelist.net/anime/.*})
        .to_return(fixture('scrapers/my_anime_list_scraper/anime_detail_movie.html'))
    end
    subject { described_class.new('https://myanimelist.net/anime/306/Your_Name') }

    it 'should return a URI' do
      expect(subject.poster_image).to be_a(URI)
    end

    it 'should return the large image' do
      expect(subject.poster_image.to_s).to include('l.')
    end
  end

  describe '#subtype' do
    context 'for a movie' do
      before do
        stub_request(:get, %r{https://myanimelist.net/anime/.*})
          .to_return(fixture('scrapers/my_anime_list_scraper/anime_detail_movie.html'))
      end
      subject { described_class.new('https://myanimelist.net/anime/306/Your_Name') }

      it 'should return :movie' do
        expect(subject.subtype).to eq(:movie)
      end
    end

    context 'for a TV series' do
      before do
        stub_request(:get, %r{https://myanimelist.net/anime/.*})
          .to_return(fixture('scrapers/my_anime_list_scraper/anime_detail_tv.html'))
      end
      subject { described_class.new('https://myanimelist.net/anime/306/Abenobashi') }

      it 'should return :tv' do
        expect(subject.subtype).to eq(:tv)
      end
    end

    context 'for a hentai novel' do
      before do
        stub_request(:get, %r{https://myanimelist.net/manga/.*})
          .to_return(fixture('scrapers/my_anime_list_scraper/manga_detail_empty.html'))
      end
      subject { described_class.new('https://myanimelist.net/manga/109855/Mamono_Friends') }

      it 'should return :novel' do
        expect(subject.subtype).to eq(:novel)
      end
    end

    context 'for a manga' do
      before do
        stub_request(:get, %r{https://myanimelist.net/manga/.*})
          .to_return(fixture('scrapers/my_anime_list_scraper/manga_detail_ongoing.html'))
      end
      subject { described_class.new('https://myanimelist.net/manga/13/One_Piece') }

      it 'should return :manga' do
        expect(subject.subtype).to eq(:manga)
      end
    end
  end

  describe '#synopsis' do
    before do
      stub_request(:get, %r{https://myanimelist.net/anime/.*})
        .to_return(fixture('scrapers/my_anime_list_scraper/anime_detail_tv.html'))
    end
    subject { described_class.new('https://myanimelist.net/anime/306/Abenobashi') }

    it 'should return the synopsis as text' do
      expect(subject.synopsis).to be_a(String)
      expect(subject.synopsis).to eq(<<~SYNOPSIS.strip)
        Satoshi "Sasshi" Imamiya believes his life is in shambles, as only a 12-year-old can. Having lost his card collection, his childish dilemmas worsen when he learns that his childhood friend, Arumi Asahina, will be moving away.

        Suddenly, their issues are dashed aside for the surreal, and they find themselves transported away through bizarre worlds of science fiction, magic, and war. Any attempt to escape only catapults them into another alien land. Soon, the two come to a realization: every world is just a reimagining of their hometown. But there are two unfamiliar faces—the voluptuous Mune-mune and the elusive blue-haired Eutus—and they just might be the key to escaping their predicament.

        Abenobashi Mahou☆Shoutengai follows Sasshi and Arumi's comedic exploits as they desperately attempt to return home. However, when the pair unravel a tale spanning generations, they begin to wonder if the cause of their situation is more personal than they thought. Is returning home truly what they desire?
      SYNOPSIS
    end

    it 'should remove stray citations' do
      expect(subject.synopsis).not_to include('Source:')
      expect(subject.synopsis).not_to include('MAL Rewrite')
    end

    context 'with no data' do
      before do
        stub_request(:get, %r{https://myanimelist.net/manga/.*})
          .to_return(fixture('scrapers/my_anime_list_scraper/manga_detail_empty.html'))
      end
      subject { described_class.new('https://myanimelist.net/manga/306/Test') }

      it 'should return nil' do
        expect(subject.synopsis).to be_nil
      end
    end
  end

  describe '#background' do
    context 'with no data' do
      before do
        stub_request(:get, %r{https://myanimelist.net/manga/.*})
          .to_return(fixture('scrapers/my_anime_list_scraper/manga_detail_empty.html'))
      end
      subject { described_class.new('https://myanimelist.net/manga/306/Test') }

      it 'should return nil' do
        expect(subject.background).to be_nil
      end
    end

    context 'with data' do
      before do
        stub_request(:get, %r{https://myanimelist.net/anime/.*})
          .to_return(fixture('scrapers/my_anime_list_scraper/anime_detail_tv.html'))
      end
      subject { described_class.new('https://myanimelist.net/anime/306/Abenobashi') }

      it 'should return the background info as text' do
        expect(subject.background).to be_a(String)
        expect(subject.background).to eq(<<~BACKGROUND.strip)
          Abenobashi Mahou☆Shoutengai received an Excellence Prize for animation at the 2002 Japan Media Arts Festival.
        BACKGROUND
      end
    end
  end

  describe '#genres' do
    before do
      stub_request(:get, %r{https://myanimelist.net/anime/.*})
        .to_return(fixture('scrapers/my_anime_list_scraper/anime_detail_tv.html'))
    end
    subject { described_class.new('https://myanimelist.net/anime/306/Abenobashi') }

    it 'should return a list of Genres' do
      expect(subject.genres).to all(be_a(Genre))
    end
  end

  describe '#abbreviated_titles' do
    before do
      stub_request(:get, %r{https://myanimelist.net/anime/.*})
        .to_return(fixture('scrapers/my_anime_list_scraper/anime_detail_tv.html'))
    end
    subject { described_class.new('https://myanimelist.net/anime/306/Abenobashi') }

    it 'should return a list of synonymous titles' do
      expect(subject.abbreviated_titles).to be_an(Array)
      expect(subject.abbreviated_titles).to include('Magical Shopping Arcade Abenobashi')
    end
  end
end
