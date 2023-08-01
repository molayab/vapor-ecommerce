import settingsIcon from '/settings.svg';

function RateStarList({ rate }) {
  const stars = [];
  for (let i = 0; i < rate; i += 1) {
    stars.push(<img src={settingsIcon} alt='settings' />);
  }

  return (
    <div className='flex'>
      {stars}
    </div>
  );
}

export default RateStarList;