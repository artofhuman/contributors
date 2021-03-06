RSpec.describe ContributorRepository do
  let(:repo) { ContributorRepository.new }
  let(:contributor) { repo.create(github: 'davydovanton') }

  let(:commit_repo) { CommitRepository.new }

  after { repo.clear }

  describe '#find_by_github' do
    context 'when contributor has commits' do
      after { commit_repo.clear }

      it { expect(repo.find_by_github(contributor.github)).to be_a Contributor }
      it { expect(repo.find_by_github(contributor.github).github).to eq contributor.github }
    end

    context 'when contributor does not have commits' do
      it { expect(repo.find_by_github('github')).to eq nil }
    end
  end

  describe '#with_commit_range' do
    before do
      other_commiter = repo.create(github: 'test')

      commit_repo.create(contributor_id: contributor.id, created_at: Time.now - 60 * 60 * 22)
      commit_repo.create(contributor_id: other_commiter.id, created_at: Time.now - 60 * 60 * 24 * 5)
    end

    after { commit_repo.clear }

    let(:range) { (Time.now - 60 * 60 * 24)..Time.now }

    it { expect(repo.with_commit_range(range).count).to eq 1 }
    it { expect(repo.with_commit_range(range).last.github).to eq 'davydovanton' }
    it { expect(repo.with_commit_range(range).last.commits_count).to eq 1 }
  end

  describe '#fill_since' do
    let(:yearday) { (Time.now - 60 * 60 * 24).utc }
    let(:now) { Time.now.utc }

    before do
      commit_repo.create(contributor_id: contributor.id, created_at: yearday)
      commit_repo.create(contributor_id: contributor.id, created_at: now)
    end

    it 'fills since column' do
      repo.fill_since

      expect(repo.contributors.where(id: contributor.id).one.since.to_i)
        .to eq(yearday.to_i)
    end
  end
end
