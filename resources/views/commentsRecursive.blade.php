@foreach($comments as $comment)
    <div class="ml-5">Comment:{{$comment->body}} [{{$comment->commentable_type}}]
        <a href="{{getenv('FORUM_CLIENT')}}/deleteComment/{{$forum_id}}/{{$forum_slug}}/{{$topic_id}}/{{$topic_slug}}/{{$comment->id}}?apikey={{getenv('API_KEY')}}"><i
                class="fa fa-trash text-gray-300 hover:text-black"></i></a>
    </div>
    <div>
        <form class="bg-slate-100 p-5" method="POST"
              action="{{getenv('FORUM_CLIENT')}}/storeCommentCommentPost">
            @csrf

            <input type="hidden" id="forum_id" name="forum_id" value="{{$forum_id}}">
            <input type="hidden" id="forum_slug" name="forum_slug" value="{{$forum_slug}}">
            <input type="hidden" id="topic_id" name="topic_id" value="{{$topic_id}}">
            <input type="hidden" id="topic_slug" name="topic_slug" value="{{$topic_slug}}">
            <input type="hidden" id="id" name="id" value="{{$comment->id}}">

            <div>
                <textarea name="body" id="body" rows="2" cols="40"
                          placeholder="What are your thoughts?">{{old('body')}}</textarea>
                Author: <input type="text" name="author_id" id="author_id" size="38"
                               value="{{old('author_id')}}">
                Status: <select name="status" id="status">
                    <option value="Active">Active</option>
                    <option value="Draft">Draft</option>
                    <option value="Pending Review">Pending Review</option>
                    <option value="Locked">Locked</option>
                    <option value="Removed">Removed</option>
                </select>
            </div>

            <div class="p-5 text-right">
                <button class="btn" type="submit">
                    Submit
                </button>
            </div>
        </form>

    @if(!empty($comment->comments))
        @include('commentsRecursive',['comments' => $comment->comments])
    @endif
@endforeach
