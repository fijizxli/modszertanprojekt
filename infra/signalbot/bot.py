import anyio
import os
from semaphore import Bot, ChatContext, Mention, JobQueue, Message, Address
import aioconsole
import code
import logging
import re
logging.basicConfig(level=logging.DEBUG)

from collections import defaultdict

import threading

from flask import Flask
from flask import request

app = Flask(__name__)


from queue import Queue
notification_q = Queue()

from json import loads
from types import SimpleNamespace # https://stackoverflow.com/questions/6578986/how-to-convert-json-data-into-a-python-object


from textwrap import dedent

#        HookEventCreate                    HookEventType = "create"
#        HookEventDelete                    HookEventType = "delete"
#        HookEventFork                      HookEventType = "fork"
#        HookEventPush                      HookEventType = "push"
#        HookEventIssues                    HookEventType = "issues"
#        HookEventIssueAssign               HookEventType = "issue_assign"
#        HookEventIssueLabel                HookEventType = "issue_label"
#        HookEventIssueMilestone            HookEventType = "issue_milestone"
#        HookEventIssueComment              HookEventType = "issue_comment"
#        HookEventPullRequest               HookEventType = "pull_request"
#        HookEventPullRequestAssign         HookEventType = "pull_request_assign"
#        HookEventPullRequestLabel          HookEventType = "pull_request_label"
#        HookEventPullRequestMilestone      HookEventType = "pull_request_milestone"
#        HookEventPullRequestComment        HookEventType = "pull_request_comment"
#        HookEventPullRequestReviewApproved HookEventType = "pull_request_review_approved"
#        HookEventPullRequestReviewRejected HookEventType = "pull_request_review_rejected"
#        HookEventPullRequestReviewComment  HookEventType = "pull_request_review_comment"
#        HookEventPullRequestSync           HookEventType = "pull_request_sync"
#        HookEventPullRequestReviewRequest  HookEventType = "pull_request_review_request"
#        HookEventWiki                      HookEventType = "wiki"
#        HookEventRepository                HookEventType = "repository"
#        HookEventRelease                   HookEventType = "release"
#        HookEventPackage                   HookEventType = "package"


from types import FunctionType

#TODO?
mentionmap = {
  "@cbaksay":"3f09562e-7caa-4336-b123-11de164c26c9",
  "@fijizxli":"36c640fd-f022-4795-838b-1c6c5756e255",
  "@aeternum-dev":"6c1b0055-b0bd-49c2-a52c-75310c972eb7",
#  "@gergo":"8fc05e2c-75e2-408e-a8bd-4d378a413ce4"
  }
gitea_mentions_regex = "|".join(mentionmap.keys())


@app.route("/v1/handle_webhook", methods=["GET","POST"])
def handle_webhook(q=notification_q): #TODO is this correct?
    type_handlers = defaultdict(lambda x: None, {})

    # brings values from a SimpleNamespace into scope in the called handler
    def magic_match(evt_type):
      def decorate(f):
        print(f"decorating {f}")
        def proxy(ns):
          nonlocal f
          nns = dict(f.__globals__)
          nns.update(vars(ns))
          nns["_ns"] = ns
          f = FunctionType(f.__code__, nns, f.__name__, f.__defaults__, f.__closure__)
          return f()
        type_handlers[evt_type] = proxy
        return proxy
      return decorate

    def debug(f):
      def g(*args,**kwargs):
        print((args, kwargs))
        r = f(*args,**kwargs)
        print(r)
        return r
      return g

    #meg nincs issue_label event_type, (actions: "label_updated", "label_cleared") mert ugy mukodik, mint az assign

    @magic_match("create")
    def on_create():
      return f"""{sender.username} created a new {ref_type} for the repository {repository.name}."""

    @magic_match("delete")
    def on_delete():
      return f"""{sender.username} deleted a {ref_type} from the repository {repository.name}."""

    @magic_match("fork")
    def on_fork():
      return f"""{forkee.name} by {forkee.owner.username} was forked by {repository.owner.username} with the name {repository.name}."""

    @magic_match("push")
    def on_push():
      return f"""New push by: {pusher.username} in {repository.name}, head commit: {head_commit.message}""" + "\n" + f"""Check the changes at: {compare_url}"""

    @magic_match("issues")
    def on_issue():
      #TODO not sure if these are all even passed to this
      if action in ("opened", "closed", "reopened", "edited", "assigned", "unassigned", "reviewed", "review_requested"):
        return f"""Issue {action.replace("_", " ")} in {repository.name}: #{number} {issue.title} ({issue.url})"""
      else:
        return _ns

    @magic_match("issue_assign")
    def on_issue_assign():
      # nem lesz unassigned mert nincs benne a jsonben hogy kivel tortent az esemeny
      if (action == "assigned"):
        x = ", ".join(i.username for i in issue.assignees)
        return dedent(f"""
          {x} got assigned issue #{issue.number}: "{issue.title}". ({issue.url})
          """).strip()
      else:
        return str(_ns)

    @magic_match("issue_comment")
    def on_issue_comment():
      if action in ("created", "edited", "deleted"):
        return dedent(f"""
          Issue comment {action} on issue #{issue.number} ({issue.title}): "{comment.body}" by {comment.user.username}
          """).strip()
      else:
        return _ns

    @magic_match("issue_label")
    def on_issue_label():
      if action in ("label_updated", "label_cleared"):
        return dedent(f"""
          Label added to issue.
          """).strip()
      else:
        return _ns

    @magic_match("pull_request")
    def on_pull_request():
      return dedent(f"""{pull_request.user.username} {action} a pull request with the title \"{pull_request.title}.\"
      		({pull_request.html_url})""").strip()

    @magic_match("pull_request_comment")
    def on_pull_request_comment():
      return dedent(f"""{comment.user.username} commented \"{comment.body}\" on the pull request \"{issue.title}\".
              ({comment.pull_request_url})""").strip()

    def on_review():
      pass

    @magic_match("pull_request_review_comment")
    def on_pull_request_review_comment():
      return f"""{pull_request.title} {action} by {sender.username}: {review.content}"""

    @magic_match("repository")
    def on_repo():
      return f"""{repository.name} {action} by {sender.username}."""

    @magic_match("release")
    def on_release():
      releases_url = f"""{release.html_url}"""
      return f"""{release.author.username} {action} a release with the name {release.name}.""" + "\n" + f"""{release.html_url}"""

    @magic_match("wiki")
    def on_wiki	():
      return f"""{sender.username} {action} the \"{page}\" wiki page in the {repository.name} repository."""

    def translate(ns):
      return type_handlers[ns.event_type](ns)

    # Load json as dot-traversable objects instead of dicts based)
    ns = loads(request.values["payload"], object_hook=lambda d: SimpleNamespace(**d))
    if result := translate(ns):
      q.put((ns, result))

    return request.values["payload"]


ownnumber = os.environ["SIGNAL_ACCT"]
notifgroup = os.environ["SIGNAL_NOTIF_GROUP"]
# Connect the bot to number.
bot = Bot(ownnumber)
ownuuid = None


#TODO need to keep this in sync
group_members = dict() #TODO BUG need to make per channel?

@bot.handler('')
async def process_message(ctx: ChatContext) -> None:
    global ownuuid
    global group_members

    if not ownuuid:
      ownuuid = (await ctx.bot.list_accounts())[0]["address"]["uuid"]
    if (gid := ctx.message.get_group_id()) not in group_members:
      group_members[gid] = (await ctx.bot.get_group(gid)).members

    mentions = None
    if "@all" in ctx.message.get_body().lower():
      mentions = [Mention(uuid=member["uuid"], start=(i*2)+1, length=1) for i, member in enumerate(group_members[gid]) if member["uuid"] != ownuuid ] #TODO BUG need to make per channel?
      await ctx.message.reply(" " + u"\uFFFC "*len(mentions), mentions=mentions)
    else:
      pass


def intermediate_to_signal_human(str):
  mentions = list()
  def sideeffectful(match):
    nonlocal mentions
    #TODO how to get number of groups?
    mentions.append(Mention(uuid=mentionmap[match.group(0)], start=match.span()[0], length=1)) #TODO position base?
    return u"\uFFFC"
  print((str, gitea_mentions_regex))
  str = re.sub(gitea_mentions_regex, sideeffectful, str)
  return (str,mentions)

async def poll(ctx):
  if not notification_q.empty():
    ns, notif_text = notification_q.get()
    notif_text, mentions = intermediate_to_signal_human(notif_text)
#    await aioconsole.interact(locals=locals())
#    await ctx.bot.send_message(notifgroup, u"\uFFFC adsdfsdsd"+notif, mentions=[Mention(uuid="3f09562e-7caa-4336-b123-11de164c26c9", start=0, length=1)])
    print(notif_text)
    print(mentions)
    await ctx.bot.send_message(notifgroup, notif_text, mentions=mentions)

async def main():
    from time import time
    async with bot:
        ##TODO bad hack because I dont know how to get the sequencing right here; .start() is blocking so we cant really put this after that
        ## needs to be run after start, these fields are inited in start
        #async def f():
        #  await anyio.sleep(2)
        #  #TODO hack because we cant see the attrib for some reason
        #  job = JobQueue(bot._sender)
        #  job.run_repeating(time(), poll_notif, bot._chat_context, 3) #TODO kinda meh#TODO correct?
        #  async with anyio.create_task_group() as tg:
        #    await tg.spawn(job.start)
        #await f()
        ##await aioconsole.interact(locals=locals())

        #async def f():
        #  await anyio.sleep(2)
        #  bot._job_queue.run_repeating(time(), poll_notif, bot._chat_context, 3) #TODO kinda meh#TODO correct?
        #await f()

        async def callback(bot):
          await bot._job_queue.run_repeating(time(), poll, ChatContext(Message(source=Address(""), username=None, envelope_type=None, timestamp=None, server_timestamp=None, sender=None), None, bot._job_queue, bot), 3) #TODO kinda meh#TODO correct?
          #await aioconsole.interact(locals=locals())

        # Run the bot until you press Ctrl-C.
        await bot.start(callback)

def _main():
    t = threading.Thread(target=app.run).start()
    anyio.run(main)

_main()
