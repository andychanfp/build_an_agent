class BuildAnAgent < Formula
  desc "Claude Code skills pipeline for building and auditing AI agents"
  homepage "https://github.com/andychanfp/build_an_agent"
  url "https://github.com/andychanfp/build_an_agent/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_RUN: curl -sL https://github.com/andychanfp/build_an_agent/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256"
  license "MIT"

  SKILLS = %w[
    agent-audit
    agent-audit-benchmark
    agent-audit-grade
    agent-audit-lint
    agent-audit-optimise
    agent-audit-test
    agent-build
    agent-evaluate
    agent-fix
    agent-plan
    agent-quality
  ].freeze

  def install
    SKILLS.each do |skill|
      src = buildpath/".claude/skills/#{skill}"
      next unless src.directory?
      skill_dst = share/"build-an-agent/skills/#{skill}"
      skill_dst.mkpath
      src.children.each { |f| FileUtils.cp_r(f, skill_dst) }
      FileUtils.rm_rf(skill_dst/"run")
    end
  end

  def post_install
    claude_dir = Pathname.new("#{Dir.home}/.claude")
    unless claude_dir.directory?
      opoo "~/.claude not found — is Claude Code installed? " \
           "After installing Claude Code, run: brew reinstall build-an-agent"
      return
    end

    claude_skills = claude_dir/"skills"
    claude_skills.mkpath

    SKILLS.each do |skill|
      src = share/"build-an-agent/skills/#{skill}"
      dst = claude_skills/skill
      dst.rmtree if dst.exist?
      FileUtils.cp_r(src, dst)
    end

    ohai "#{SKILLS.size} skills installed to ~/.claude/skills/"
  end

  def caveats
    <<~EOS
      Open any Claude Code session and type /agent-plan to start building.

      To update skills to the latest version:
        brew upgrade build-an-agent

      If ~/.claude was not found at install time, install Claude Code first:
        https://claude.ai/download
      Then run: brew reinstall build-an-agent
    EOS
  end
end
