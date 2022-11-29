@extends('layout.master')

@section('content')
    <div class="flex h-screen">
        <div class="flex-1 flex flex-col overflow-hidden">
            <header class="flex justify-between items-center bg-gray-300 p-4 rounded-lg">
                <div class="flex">
                    <button class="bg-blue-800 rounded-lg p-3 text-white hover:bg-blue-600">
                        <a href="{{getenv('FORUM_CLIENT')}}">Forums</a>
                    </button>
                </div>
                <div class="flex">
                    <button class="bg-blue-800 rounded-lg p-3 text-white hover:bg-blue-600">
                        <a href="{{getenv('FORUM_CLIENT')}}/createTopic/{{$forum_content->id}}/{{$forum_content->slug}}?apikey={{getenv('API_KEY')}}">Create
                            New Topic</a>
                    </button>
                </div>
                <div class="flex max-w-[70%]">
                <span>
                <span class="text-black font-extrabold">{{$forum_content->title}}</span><br>
                {{$forum_content->body}}
                    </span>
                </div>
            </header>

            <div class="flex max-h-[90%]">
                <main class="flex flex-col w-full bg-white overflow-y-auto overflow-x-auto">
                    <div>
                        @foreach($topics_content as $item)
                            <div class="border-2 m-2 p-5">
                                <a href="{{getenv('FORUM_CLIENT')}}/upvoteTopic/{{$forum_content->id}}/{{$forum_content->slug}}/{{$item->id}}?apikey={{getenv('API_KEY')}}"><i
                                        class="fa fa-arrow-up text-green-900"></i></a>
                                <span class="font-bold text-blue-400">{{$item->score}}</span>
                                <a href="{{getenv('FORUM_CLIENT')}}/downvoteTopic/{{$forum_content->id}}/{{$forum_content->slug}}/{{$item->id}}?apikey={{getenv('API_KEY')}}"><i
                                        class="fa fa-arrow-down text-red-900"></i></a>
                                <span class="text-2xl">
                                <a href="{{getenv('FORUM_CLIENT')}}/topicShow/{{$forum_content->id}}/{{$forum_content->slug}}/{{$item->id}}/{{$item->slug}}?apikey={{getenv('API_KEY')}}"><B>{{$item->title}}</B></a>
                            </span>
                                <a href="{{getenv('FORUM_CLIENT')}}/editTopic/{{$forum_content->id}}/{{$forum_content->slug}}/{{$item->slug}}?apikey={{getenv('API_KEY')}}"><i
                                        class="fa fa-pen text-gray-300 hover:text-black"></i></a>
                                <a href="{{getenv('FORUM_CLIENT')}}/deleteTopic/{{$forum_content->id}}/{{$forum_content->slug}}/{{$item->id}}?apikey={{getenv('API_KEY')}}"><i
                                        class="fa fa-trash text-gray-300 hover:text-black"></i></a>
                                <a href="{{getenv('FORUM_CLIENT')}}/reportTopic/{{$forum_content->id}}/{{$forum_content->slug}}/{{$item->id}}?apikey={{getenv('API_KEY')}}"><i
                                        class="fa fa-flag text-gray-300 hover:text-black"></i></a>
                                <br>
                                <span>{{$item->body}}</span>
                                <br>
                                Type:{{$item->type}} Status:{{$item->status}}
                                <br>
                                <span class="text-gray-400">Posted by:{{$item->author_id}}</span>
                                <br>
                                @foreach($item->tag_names as $tag)
                                    <div class="float-left bg-blue-900 rounded-lg text-white p-2 m-2">{{$tag}}</div>
                                @endforeach
                                @if(!empty($item->reports))
                                    <div class="clear-both">Reports:</div>
                                    @foreach($item->reports as $report)
                                        <div>By:{{$report->author_id}} | Status:{{$report->status}} | Type:{{$report->type}}
                                            <a href="{{getenv('FORUM_CLIENT')}}/approveReport/{{$forum_content->id}}/{{$forum_content->slug}}/{{$report->id}}?apikey={{getenv('API_KEY')}}"><i
                                                    class="fa fa-check"></i></a>
                                            <a href="{{getenv('FORUM_CLIENT')}}/declineReport/{{$forum_content->id}}/{{$forum_content->slug}}/{{$report->id}}?apikey={{getenv('API_KEY')}}"><i
                                                    class="fa fa-comment-slash"></i></a>
                                        </div>
                                    @endforeach
                                @endif
                            </div>
                        @endforeach
                    </div>
                </main>
                <side class="flex bg-slate-300 overflow-y-auto max-w-[50%]">
                    <div>
                        <div class="bg-blue-900 text-white text-center font-bold">Forum Moderators</div>
                        <div class="m-2 p-2">
                            @foreach($moderators_content as $item)
                                <div>
                                    {{$item->author_id}}
                                    @if(Session::has('author_id'))
                                        @if(Session::get('author_id') == $forum_content->author_id)
                                         <a href="{{getenv('FORUM_CLIENT')}}/deleteModerator/{{$forum_content->id}}/{{$forum_content->slug}}/{{$item->id}}?apikey={{getenv('API_KEY')}}"><i
                                            class="fa fa-trash text-gray-400 hover:text-black"></i></a>
                                        @endif
                                    @endif
                                </div>
                            @endforeach
                            <div class="text-right m-2">
                                @if(Session::has('author_id'))
                                    @if(Session::get('author_id') == $forum_content->author_id)
                                <a href="{{getenv('FORUM_CLIENT')}}/createModerator/{{$forum_content->id}}/{{$forum_content->slug}}?apikey={{getenv('API_KEY')}}">
                                    <button class="btn">Create Moderator</button>
                                </a>
                                    @endif
                                    @endif
                            </div>
                        </div>

                        <div class="bg-blue-900 text-white text-center font-bold">Forum Rules</div>
                        <div class="m-2 p-2">
                            @foreach($rules_content as $item)
                                <div class="border-2 border-solid border-slate-400 m-2 p-2">
                                    {{$item->body}} [{{$item->status}}]
                                    @if(Session::has('author_id'))
                                        @if(Session::get('author_id') == $forum_content->author_id)
                                    <a href="{{getenv('FORUM_CLIENT')}}/editRule/{{$forum_content->id}}/{{$forum_content->slug}}/{{$item->id}}?apikey={{getenv('API_KEY')}}"><i
                                            class="fa fa-pen text-gray-400 hover:text-black"></i></a>
                                    <a href="{{getenv('FORUM_CLIENT')}}/deleteRule/{{$forum_content->id}}/{{$forum_content->slug}}/{{$item->id}}?apikey={{getenv('API_KEY')}}"><i
                                            class="fa fa-trash text-gray-400 hover:text-black"></i></a>
                                        @endif
                                        @endif
                                </div>
                            @endforeach

                                @if(Session::has('author_id'))
                                    @if(Session::get('author_id') == $forum_content->author_id)

                            <div class="text-right m-2">
                                <a href="{{getenv('FORUM_CLIENT')}}/deleteAllRule/{{$forum_content->id}}/{{$forum_content->slug}}?apikey={{getenv('API_KEY')}}">
                                    <button class="btn">Remove All
                                        Rules
                                    </button>
                                </a>
                                <a href="{{getenv('FORUM_CLIENT')}}/createRule/{{$forum_content->id}}/{{$forum_content->slug}}?apikey={{getenv('API_KEY')}}">
                                    <button class="btn">Create Rule
                                    </button>
                                </a>
                            </div>
                                    @endif
                                    @endif
                        </div>

                        <div class="bg-blue-900 text-white text-center font-bold">Forum Tags</div>
                        <div class="m-2 p-2">
                            @foreach($tags_content as $tag)
                                    <button
                                        class="bg-gray-400 rounded-lg text-white p-2 m-1 border-1 border-black border-solid">{{$tag->name}}</button>
                                    @if(Session::has('author_id'))
                                        @if(Session::get('author_id') == $forum_content->author_id)
                                        <a href="{{getenv('FORUM_CLIENT')}}/deleteForumTag/{{$forum_content->id}}/{{$forum_content->slug}}/{{$tag->id}}?apikey={{getenv('API_KEY')}}"><i
                                            class="fa fa-trash text-gray-400 hover:text-black"></i></a>
                                        @endif
                                        @endif
                            @endforeach

                                @if(Session::has('author_id'))
                                    @if(Session::get('author_id') == $forum_content->author_id)

                                    <div class="text-right m-2">
                                <a href="{{getenv('FORUM_CLIENT')}}/createForumTag/{{$forum_content->id}}/{{$forum_content->slug}}">
                                <button class="btn">Create Tag
                                </button>
                                </a>
                            </div>
                                    @endif
                                    @endif
                        </div>

                    </div>
                </side>
            </div>
        </div>
    </div>
@endsection


@section('footer')
    <footer>© 2022 Client Forum</footer>
@endsection
