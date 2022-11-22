@foreach($comments as $comment)
    <div class="ml-5">Comment:{{$comment->body}}</div>
    @if(!empty($comment->comments))
        <div class="ml-5">
        @include('commentsRecursive',['comments' => $comment->comments])
        </div>
    @endif
@endforeach
