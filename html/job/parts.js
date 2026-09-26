window.TwJobParts = {
  menu: `
    <Transition name="fade">
      <div class="newGeneral" v-show="state.mainShow">
        <div class="otherJobCover" v-if="playerData && playerData.otherJob">
          <div class="otherJobCard">
            <div class="otherJobText">{{ playerData.otherJob.text }}</div>
            <div class="otherJobLeave" @click="leaveOtherJob()">{{ playerData.otherJob.leave }}</div>
            <div class="otherJobClose" @click="closeNUI()">{{ playerData.otherJob.close }}</div>
          </div>
        </div>
        <div class="newMenu">
          <div class="newCategoryList">
            <div class="newCategory" v-if="!state.tutorialOnly"
              :class="state.currentPage == 'home' ? 'newSelectCategory' : ''"
              @click="changePage('home')">
              <i class="ncIcon ncHome"></i>
              <span class="ncLabel">{{state.locales['homePage']}}</span>
            </div>
            <tw-job-tabs></tw-job-tabs>
            <div class="newCategory" v-if="state.tutorialList.length"
              :class="state.currentPage == 'tutorial' ? 'newSelectCategory' : ''"
              @click="changePage('tutorial')">
              <i class="ncIcon ncTutorial"></i>
              <span class="ncLabel">{{state.locales['tutorialTab'] || 'Tutorial'}}</span>
            </div>
            <div class="newCategory" v-if="!state.tutorialOnly"
              :class="state.currentPage == 'settings' ? 'newSelectCategory' : ''"
              @click="changePage('settings')">
              <i class="ncIcon ncSettings"></i>
              <span class="ncLabel">{{state.locales['settings']}}</span>
            </div>
            <div class="newCategory" v-if="leaderboardEnabled && !state.tutorialOnly"
              :class="state.currentPage == 'leaderboard' ? 'newSelectCategory' : ''"
              @click="changePage('leaderboard')">
              <i class="ncIcon ncLeaderboard"></i>
              <span class="ncLabel">{{state.locales['leaderboard'] || 'Leaderboard'}}</span>
            </div>
          </div>
          <div class="newExitBox" @click="closeNUI">
            <img :src="lib + 'img/Icon/exitIcn.svg'" alt="" />
          </div>
          <div class="newTitleBox">
            <div class="newTitleIcon">
              <img :src="ui.logo" alt="" class="newLogo" />
            </div>
            <div class="newTitleTextBox">
              <h2 class="newTitleText">{{state.serverName}}</h2>
              <p class="newTitleSubText">{{state.scriptName}}</p>
            </div>
          </div>
          <div class="newTopSide">
            <div class="newLevelSide">
              <div class="newLevelIcon">
                <h2 class="newLevelSay">{{playerData.playerLevel}}</h2>
                {{state.locales['LVL']}}
              </div>
              <div class="newLevelRightSide">
                <h2 class="newLevelText">
                  {{state.locales['Level']}} {{playerData.playerLevel}}
                </h2>
                <div class="newLevelProgress">
                  <div class="newLevelProgressSay" :style="{ width: progressPercentage + '%' }"></div>
                </div>
                <div class="newLevelExpSide">
                  <h2 class="newLevelExp">
                    {{formatNumber(playerData.playerXp)}}
                    {{state.locales['Exp']}}
                  </h2>
                  <h2 class="newLevelExp">
                    {{formatNumber(playerData.playerNextXp)}}
                    {{state.locales['Exp']}}
                  </h2>
                </div>
              </div>
            </div>
          </div>
          <div class="newBottomSide newHomePage" v-show="state.currentPage == 'home'">
            <div class="newRegionBox">
              <div class="newRegionBoxTopSide">
                <div class="newMenuTitleBox">
                  <img :src="lib + 'img/Icon/locationIcn.svg'" alt="" />
                  <div class="newMenuTitleTextBox">
                    <h2 class="newMenuTitleText">
                      {{state.locales['selectjobregion'] || 'Select a region'}}
                    </h2>
                    <p class="newMenuTitleSubText">
                      {{state.locales['Choose']}}
                    </p>
                  </div>
                </div>
                <div class="newMenuArrowSide" v-show="!state.expandedRegion">
                  <div class="newMenuArrow" :class="{ 'active-arrow': canGoPrev }" @click="prevRegion">
                    <img :src="lib + 'img/Icon/arrowIcn.svg'" alt="" />
                  </div>
                  <div class="newMenuArrow" :class="{ 'active-arrow': canGoNext }" @click="nextRegion">
                    <img :src="lib + 'img/Icon/arrowIcn.svg'" alt="" />
                  </div>
                </div>
              </div>
              <div class="newRegionList newRegionGrid" ref="regionList"
                v-show="!state.expandedRegion || state.heroPhase === 'expanding'"
                :class="{ 'newGridDim': state.heroPhase === 'expanding', 'newGridRestore': state.heroPhase === 'restoring', 'newGridPageRight': state.gridPaging === 'right', 'newGridPageLeft': state.gridPaging === 'left' }">
                <div class="newRegion newRegionCompact" v-for="(region, index) in displayedRegions" :key="region.regionID"
                  :data-region-id="region.regionID"
                  @click="onRegionClick(region, $event)"
                  :style="{'opacity': state.selectedRegion && region.regionID === state.selectedRegion.regionID ? 1 : (state.selectedRegion ? 0.5 : 1), 'background': region.illegalMission ? 'linear-gradient(180deg, rgba(255, 0, 0, 0.1) 0%, rgba(0, 0, 0, 0.2) 100%)' : ''}"
                  :class="{'illegal-mission': region.illegalMission, 'newRegionSelect': state.selectedRegion && region.regionID === state.selectedRegion.regionID}">
                  <div class="newRegionTopSide" v-if="region.regionInfo">
                    <div class="newRegionNameBox">
                      <div class="newRegionNameIcon">
                        <img :src="lib + 'img/Icon/location2Icon.svg'" alt="" />
                      </div>
                      <div class="newRegionNameTextBox">
                        <h2 class="newRegionNameText">
                          {{state.locales['Region']}} {{region.regionID}}
                        </h2>
                        <p class="newRegionNameSubText">
                          {{region.regionInfo.regionName}}
                        </p>
                      </div>
                    </div>
                    <div class="newRegionDetailBox" v-if="region.regionInfo">
                      <div class="newRegionDetail" :class="{'newCrewBadDetail': crewIncompatible(region)}">
                        {{crewLabel(region)}}
                      </div>
                      <div class="newRegionDetailLine"></div>
                      <div class="newRegionDetail"
                        :class="playerData.playerLevel >= region.regionInfo.regionMinimumLevel ? '' : 'newRegionLevelDetail'">
                        {{state.locales['LVL']}} {{region.regionInfo.regionMinimumLevel}}
                      </div>
                      <template v-if="region.regionInfo.typeLabel">
                        <div class="newRegionDetailLine"></div>
                        <div class="newRegionDetail newTypeDetail">
                          {{region.regionInfo.typeLabel}}
                        </div>
                      </template>
                    </div>
                  </div>
                  <div class="newRegionBottomSide" v-if="region.regionAwards">
                    <div class="newRegionAwardBox newRegionExpAward">
                      {{formatNumber(region.regionAwards.xp)}}
                      {{state.locales['XP']}}
                    </div>

                    <div class="newRegionAwardBox newRegionMoneyAward">
                      {{formatNumber(region.regionAwards.money)}}
                      {{state.serverMoneyType}}
                    </div>
                  </div>
                  <img v-if="region.regionInfo && region.regionInfo.regionImage"
                    :src="'./img/' + region.regionInfo.regionImage" class="newRegionImg" />
                </div>
              </div>
              <div class="newRegionHero" v-if="state.expandedRegion" ref="heroCard"
                :class="{ 'newHeroFlying': state.heroPhase !== null }">
                <video v-if="heroMedia.endsWith('.webm')" class="newHeroBgMedia" :src="heroMedia" autoplay muted
                  loop></video>
                <img v-else class="newHeroBgMedia" :src="heroMedia" alt="" />
                <div class="newHeroBack" @click.stop="collapseHero">
                  <div class="newHeroBackKey">ESC</div>
                  {{state.locales['Back']}}
                </div>
                <div class="newHeroContent">
                  <div class="newHeroTitleBox">
                    <div class="newRegionNameBox">
                      <div class="newRegionNameIcon">
                        <img :src="lib + 'img/Icon/location2Icon.svg'" alt="" />
                      </div>
                      <div class="newRegionNameTextBox">
                        <h2 class="newRegionNameText">
                          {{state.locales['Region']}} {{state.expandedRegion.regionID}}
                        </h2>
                        <p class="newRegionNameSubText">
                          {{state.expandedRegion.regionInfo.regionName}}
                        </p>
                      </div>
                    </div>
                    <div class="newHeroChip newTypeDetail" v-if="state.expandedRegion.regionInfo.typeLabel">
                      {{state.expandedRegion.regionInfo.typeLabel}}
                    </div>
                  </div>
                  <p class="newHeroDesc">
                    {{state.expandedRegion.regionInfo.longDesc || state.expandedRegion.regionInfo.regionJobTask}}
                  </p>
                  <div class="newHeroSpacer"></div>
                  <div class="newHeroInfoPanel">
                    <div class="newHeroInfoRow">
                      <div class="newHeroInfoLabel">
                        <img :src="lib + 'img/Icon/playersIcon.svg'" alt="" />
                        {{state.locales['crewPeople'] || 'Players'}}
                      </div>
                      <div class="newHeroInfoValue" :class="{'newHeroInfoBad': crewIncompatible(state.expandedRegion)}">
                        {{crewLabel(state.expandedRegion)}}
                      </div>
                    </div>
                    <div class="newHeroInfoLine"></div>
                    <div class="newHeroInfoRow">
                      <div class="newHeroInfoLabel">
                        <img :src="lib + 'img/Icon/crownIcn.svg'" alt="" />
                        {{state.locales['Level']}}
                      </div>
                      <div class="newHeroInfoValue"
                        :class="{'newHeroInfoBad': playerData.playerLevel < state.expandedRegion.regionInfo.regionMinimumLevel}">
                        {{state.locales['LVL']}} {{state.expandedRegion.regionInfo.regionMinimumLevel}}
                      </div>
                    </div>
                    <template v-if="state.expandedRegion.regionInfo.machines && state.expandedRegion.regionInfo.machines.length">
                      <div class="newHeroInfoLine"></div>
                      <div class="newHeroInfoRow">
                        <div class="newHeroInfoLabel">
                          <img :src="lib + 'img/Icon/taskIcn.svg'" alt="" />
                          {{state.locales['Machines'] || 'Machines'}}
                        </div>
                        <div class="newHeroInfoValue">
                          {{state.expandedRegion.regionInfo.machines.join(' · ')}}
                        </div>
                      </div>
                    </template>
                  </div>
                  <div class="newHeroAwardList" v-if="state.expandedRegion.regionAwards">
                    <div class="newRegionAwardBox newRegionExpAward">
                      {{formatNumber(state.expandedRegion.regionAwards.xp)}} {{state.locales['XP']}}
                    </div>
                    <div class="newRegionAwardBox newRegionMoneyAward">
                      {{formatNumber(state.expandedRegion.regionAwards.money)}} {{state.serverMoneyType}}
                    </div>
                    <div class="newRegionAwardBox newHeroBonusAward" v-if="state.expandedRegion.regionAwards.bonusExtraMoney">
                      +{{formatNumber(state.expandedRegion.regionAwards.bonusExtraMoney)}} {{state.serverMoneyType}}
                      {{state.locales['TeamBonus']}}
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="newPlayerBox">
              <div class="newPlayerBoxTopSide">
                <div class="newMenuTitleBox">
                  <img :src="lib + 'img/Icon/playersIcon.svg'" alt="" />
                  <div class="newMenuTitleTextBox">
                    <h2 class="newMenuTitleText">
                      {{state.locales['PlayerList']}}
                    </h2>
                  </div>
                </div>
                <div class="rewardOpener" v-if="canSplitRewards" :class="{ open: rewardOpen }" @click.stop="toggleReward($event)">
                  <svg class="rewardOpenerIcon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="8" cy="8" r="6"/><path d="M18.09 10.37A6 6 0 1 1 10.34 18"/><path d="M7 6h1v4"/><path d="m16.71 13.88.7.71-2.82 2.82"/></svg>
                  {{ state.locales['RewardSplit'] || 'Reward Split' }}
                  <img :src="lib + 'img/Icon/inputIcn.svg'" alt="" class="rewardChev" />
                </div>
                <teleport to="body">
                  <transition name="rwDrop">
                    <div class="rewardPanel" v-if="rewardOpen && canSplitRewards" @click.stop>
                      <div class="rewardHead">
                        <div class="rewardHeadL">
                          <svg class="rewardHeadIcon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="8" cy="8" r="6"/><path d="M18.09 10.37A6 6 0 1 1 10.34 18"/><path d="M7 6h1v4"/><path d="m16.71 13.88.7.71-2.82 2.82"/></svg>
                          <div>
                            <div class="rewardTitle">{{ state.locales['RewardSplit'] || 'Reward Split' }}</div>
                            <div class="rewardSub">{{ state.locales['RewardSplitHint'] || 'The rest is shared among the others' }}</div>
                          </div>
                        </div>
                        <span class="rewardTotalBadge" :class="{ bad: rewardTotal !== 100 }">{{ rewardTotal }}%</span>
                      </div>
                      <div class="rewardEqual" @click="equalSplit()">{{ state.locales['EqualSplit'] || 'Split Evenly' }}</div>
                      <div class="rewardRows">
                        <div class="rewardRow" v-for="p in playerListData" :key="p.playerIdentifier">
                          <div class="rewardRowTop">
                            <div class="rewardAvatar" :style="{ backgroundImage: 'url(' + p.playerImage + ')' }"></div>
                            <div class="rewardInfo">
                              <span class="rewardName">{{ p.playerName }}</span>
                              <span class="rewardLevel">{{ state.locales['Level'] || 'Level' }} {{ p.playerLevel }}</span>
                            </div>
                            <div class="rewardStepper">
                              <div class="rwStep" @click="stepReward(p.playerIdentifier, -5)">&minus;</div>
                              <span class="rwVal">{{ rewardPctOf(p.playerIdentifier) }}%</span>
                              <div class="rwStep" @click="stepReward(p.playerIdentifier, 5)">+</div>
                            </div>
                          </div>
                          <div class="rewardBar"><div class="rewardBarFill" :style="{ width: rewardPctOf(p.playerIdentifier) + '%' }"></div></div>
                        </div>
                      </div>
                    </div>
                  </transition>
                </teleport>
              </div>
              <div class="newPlayerList">
                <div class="newPlayer" v-if="playerListData" v-for="(player, index) in playerListData" :key="index"
                  :style="player.offline ? { opacity: 0.45 } : null">
                  <div class="newPlayerProfileImg" :style="{ backgroundImage: 'url(' + player.playerImage + ')' }"></div>
                  <div class="newPlayerProfileTextBox">
                    <h2 class="newPlayerProfileText">
                      {{player.playerName}}
                    </h2>
                    <div class="newPlayerProfileLevel">
                      {{state.locales['Level']}} {{player.playerLevel}}<template v-if="player.offline"> · {{state.locales['playerAway'] || 'Away'}}</template>
                    </div>
                  </div>
                  <span class="pctValue pctReadonly" v-if="rewardSplitEnabled && (canSplitRewards || myRewardPct !== null)">
                    {{ rewardPctOf(player.playerIdentifier) }}%
                  </span>
                  <div class="newPlayerIcon" v-if="player.playerOwner">
                    <img :src="lib + 'img/Icon/crownIcn.svg'" alt="" />
                  </div>
                  <div class="newPlayerIcon newPlayerKickButton" @click="kickPlayer(player.playerIdentifier)" v-else>
                    <img :src="lib + 'img/Icon/closeIcn.svg'" alt="" />
                  </div>
                </div>
                <div class="newPlayer newNearbyPlayer" v-for="(player, index) in state.nearbyPlayers" :key="index"
                  @click="invitePlayer(player.playerSource)">
                  <div class="newPlayerProfileImg" :style="{ backgroundImage: 'url(' + player.playerImage + ')' }"></div>
                  <div class="newPlayerProfileTextBox">
                    <h2 class="newPlayerProfileText">
                      {{player.playerName}}
                    </h2>
                    <div class="newPlayerProfileInvite">
                      {{state.locales['invitePlayer']}}
                    </div>
                  </div>
                  <div class="newPlayerIcon">
                    <img :src="lib + 'img/Icon/addIcn.svg'" alt="" />
                  </div>
                </div>
                <div v-for="index in inviteSlots" :key="index">
                  <div v-if="!state.invitePlayerModal[index]" @click="state.invitePlayerModal[index] = true">
                    <div class="newPlayer newPlayerAddInvite">
                      <div class="newPlayerProfileImg">
                        <img :src="lib + 'img/Icon/addIcn.svg'" alt="" />
                      </div>
                      <div class="newPlayerProfileTextBox">
                        <h2 class="newPlayerProfileText">
                          {{state.locales['AddInvite']}}
                        </h2>
                      </div>
                      <div class="newPlayerIcon">
                        <img :src="lib + 'img/Icon/plusIcn.svg'" alt="" />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="newStartButton" :class="{'newStartBlocked': startBlocked}" @click="startJob">
              <span class="newStartLabel">{{startBlocked ? startBlockedText : startButtonText}}</span>
            </div>
          </div>
          <div class="newBottomSide newSettingsPage" v-show="state.currentPage == 'settings'">
            <div class="newTaskBox">
              <div class="newTaskBoxTopSide">
                <div class="newMenuTitleBox">
                  <img :src="lib + 'img/Icon/taskIcn.svg'" alt="" />
                  <div class="newMenuTitleTextBox">
                    <h2 class="newMenuTitleText">
                      {{state.locales['GeneralTaskList']}}
                    </h2>
                  </div>
                </div>
                <div class="newMenuArrowSide">
                  <div class="newMenuArrow" :class="{ 'active-arrow': canGoPrevDailyMission }"
                    @click="prevDailyMission">
                    <img :src="lib + 'img/Icon/arrowIcn.svg'" alt="" />
                  </div>
                  <div class="newMenuArrow" :class="{ 'active-arrow': canGoNextDailyMission }"
                    @click="nextDailyMission">
                    <img :src="lib + 'img/Icon/arrowIcn.svg'" alt="" />
                  </div>
                </div>
              </div>
              <div class="newTaskList">
                <div class="newTask" v-if="displayedDailyMission" v-for="(task, index) in displayedDailyMission"
                  :key="index">
                  <div class="newRegionNameBox">
                    <div class="newRegionNameIcon">
                      <img :src="lib + 'img/Icon/taskIcn.svg'" alt="" />
                    </div>
                    <div class="newRegionNameTextBox">
                      <h2 class="newRegionNameText">{{task.header}}</h2>
                      <p class="newRegionNameSubText">{{task.label}}</p>
                    </div>
                  </div>
                  <div class="newTaskProgressBox">
                    <div class="newTaskProgress" :style="{ width: task.progressbar + '%' }"></div>
                  </div>
                  <div class="newTaskAwardBox">
                    <div class="newRegionAwardBox newRegionExpAward">
                      {{task.xp}} {{state.locales['Exp']}}
                    </div>
                    <div class="newRegionAwardBox newRegionMoneyAward">
                      {{formatNumber(task.money)}} {{state.serverMoneyType}}
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="newHistoryBox">
              <div class="newHistoryBoxTopSide">
                <div class="newMenuTitleBox">
                  <img :src="lib + 'img/Icon/historyIcn.svg'" alt="" />
                  <div class="newMenuTitleTextBox">
                    <h2 class="newMenuTitleText">
                      {{state.locales['HistoryList']}}
                    </h2>
                  </div>
                </div>
              </div>
              <div class="newHistoryList">
                <div class="newHistory" v-for="(history, index) in historyData" :key="index">
                  <div class="newHistoryRegionInfo">
                    <div class="newHistoryRegionBox">
                      <div class="newHistoryRegionIcon">
                        <img :src="lib + 'img/Icon/location2Icon.svg'" alt="" />
                      </div>
                      <div class="newHistoryRegionTextBox">
                        <h2 class="newHistoryRegionText">
                          {{state.locales['Region']}}
                          {{history.historyRegionID}}
                        </h2>
                        <p class="newHistoryRegionSubText">
                          {{history.historyTotalScore}}
                          {{state.locales['Task']}}
                        </p>
                      </div>
                    </div>
                    <div class="newHistoryTimeBox">
                      <img :src="lib + 'img/Icon/timeIcn.svg'" alt="" />
                      {{history.historyTime}}
                    </div>
                  </div>
                  <div class="newHistoryLine"></div>
                  <div class="newHistoryPlayerList">
                    <div class="newHistoryPlayer" v-for="(player, index) in history.historyPlayers" :key="index">
                      {{player.playerName}}
                    </div>
                  </div>
                  <div class="newHistoryLine"></div>
                  <div class="newHistoryAwardBox">
                    <div class="newHistoryAward newRegionExpAward">
                      {{formatNumber(history.historyRewardXP)}}
                    </div>
                    <div class="newHistoryAward newRegionMoneyAward">
                      {{state.serverMoneyType}}
                      {{formatNumber(history.historyRewardMoney)}}
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="newSettingBox">
              <div class="newSettingBoxTopSide">
                <div class="newMenuTitleBox">
                  <img :src="lib + 'img/Icon/settingIcn.svg'" alt="" />
                  <div class="newMenuTitleTextBox">
                    <h2 class="newMenuTitleText">
                      {{state.locales['settings']}}
                    </h2>
                  </div>
                </div>
              </div>
              <div class="newSetting">
                <div class="newSettingTopSide">
                  <div class="newSettingCheckBox newSoundOpener" @click.stop="toggleSoundPanel">
                    {{state.locales['MenuJobSounds']}}
                    <div class="newSoundOpenBtn" :class="{ open: soundPanelOpen }">
                      {{state.locales['Adjust'] || 'Adjust'}}
                      <img :src="lib + 'img/Icon/inputIcn.svg'" alt="" />
                    </div>
                    <transition name="soundDrop">
                      <div class="soundDropdown" v-if="soundPanelOpen" @click.stop>
                        <div class="soundDropHead">
                          <span>{{state.locales['SoundSettings'] || 'Sound Settings'}}</span>
                          <div class="soundDropClose" @click.stop="closeSoundPanel">
                            <img :src="lib + 'img/Icon/closeIcn.svg'" alt="" />
                          </div>
                        </div>
                        <div class="soundList">
                          <div class="soundRow" v-for="s in soundSettings" :key="s.key" :class="{ soundOff: !s.enabled }">
                            <div class="soundRowTop">
                              <span class="soundRowLabel">{{ s.label }}</span>
                              <div class="soundSwitch" :class="{ on: s.enabled }"
                                @click="s.enabled = !s.enabled; updateSound(s)">
                                <div class="soundSwitchKnob"></div>
                              </div>
                            </div>
                            <div class="soundRowBottom">
                              <input type="range" class="soundSlider" min="0" max="100" step="1"
                                v-model.number="s.volume" @input="updateSound(s)" :disabled="!s.enabled"
                                :style="{ '--fill': s.volume + '%' }" />
                              <span class="soundPct">{{ s.volume }}%</span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </transition>
                  </div>
                  <div class="newSettingLanguageBox" :class="{ active: isActive }">
                    <div class="newSettingLanguageSelected" @click.stop="toggleDropdown">
                      {{ localeValue }}
                      <span class="arrow">
                        <img :src="lib + 'img/Icon/inputIcn.svg'" alt="Arrow" />
                      </span>
                    </div>
                    <div class="newSettingLanguageList">
                      <div v-for="option in state.languageTitle" v-if="state && state.languageTitle" :key="option.value"
                        :data-value="option.label" @click="selectOption(option)">
                        {{ option.label }}
                      </div>
                    </div>
                  </div>
                  <div class="newSettingMoveBox">
                    {{state.locales['UIMove']}}
                    <div class="newSettinMoveButton" @click="moveUI">
                      <img :src="lib + 'img/Icon/moveIcn.svg'" alt="" />
                      {{state.locales['MoveIt']}}
                    </div>
                  </div>
                </div>
                <div class="newSettingButtonList">
                  <div class="newSettingSaveButton" @click="saveSettings">
                    <span>{{state.locales['Save']}}</span>
                  </div>
                  <div class="newSettingResetButton" @click="resetSettings">
                    <span>{{state.locales['Reset']}}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="newBottomSide newLeaderboardPage" v-if="leaderboardEnabled"
            v-show="state.currentPage == 'leaderboard'">
            <div class="newLbTopSide">
              <div class="newMenuTitleBox">
                <img :src="lib + 'img/Icon/crownIcn.svg'" alt="" />
                <div class="newMenuTitleTextBox">
                  <h2 class="newMenuTitleText">{{state.locales['leaderboard'] || 'Leaderboard'}}</h2>
                  <p class="newMenuTitleSubText">{{state.locales['leaderboardSub'] || 'Top players'}}</p>
                </div>
              </div>
              <div class="newLbToggle">
                <div class="newLbToggleIndicator" :class="{ newLbIndicatorRight: leaderboardSort === 'tasks' }"></div>
                <div class="newLbTab" :class="{ newLbTabActive: leaderboardSort === 'money' }"
                  @click="setLeaderboardSort('money')">
                  {{state.locales['mostMoney'] || 'Most Money'}}
                </div>
                <div class="newLbTab" :class="{ newLbTabActive: leaderboardSort === 'tasks' }"
                  @click="setLeaderboardSort('tasks')">
                  {{state.locales['mostTasks'] || 'Most Tasks'}}
                </div>
              </div>
            </div>
            <transition-group name="lbMove" tag="div" class="newLbList">
              <div class="newLbRow" v-for="(p, i) in sortedLeaderboard" :key="p.playerIdentifier ?? i"
                :class="'newLbRank' + (i + 1)">
                <div class="newLbRankNo">{{ i + 1 }}</div>
                <img :src="p.playerImage" alt="" class="newLbAvatar" />
                <div class="newLbInfo">
                  <h2 class="newLbName">{{ p.playerName }}</h2>
                  <div class="newLbLevel">{{state.locales['Level']}} {{ p.playerLevel }}</div>
                </div>
                <div class="newLbValue">
                  <template v-if="leaderboardSort === 'money'">{{ state.serverMoneyType || '$' }}{{ formatNumber(p.moneyEarned) }}</template>
                  <template v-else>{{ formatNumber(p.tasksDone) }}<span class="newLbValueUnit">{{state.locales['tasksShort'] || 'tasks'}}</span></template>
                </div>
              </div>
            </transition-group>
            <div class="newLbEmpty" v-if="!sortedLeaderboard.length">
              {{ leaderboardLoaded
                 ? (state.locales['leaderboardEmpty'] || 'No one has finished a job yet. Be the first.')
                 : (state.locales['leaderboardLoading'] || 'Loading...') }}
            </div>
          </div>
          <div class="newBottomSide newTutoPage" v-show="state.currentPage == 'tutorial'">
            <div class="newMenuTitleBox">
              <img :src="lib + 'img/Icon/taskIcn.svg'" alt="" />
              <div class="newMenuTitleTextBox">
                <h2 class="newMenuTitleText">{{state.locales['tutorialTab'] || 'Tutorial'}}</h2>
                <p class="newMenuTitleSubText">{{state.locales['howtomakeDescription']}}</p>
              </div>
            </div>
            <div class="tutoList">
              <p class="tutoEmpty" v-if="!state.tutorialList.length">{{state.locales['NoInformation'] || 'Nothing here yet'}}</p>
              <div class="tutoBox" :class="{ openTutoBox: item.isOpen }" v-for="(item, index) in state.tutorialList"
                :key="item.id || index" @click="toggleBox(index)">
                <h2 class="tutoBoxName">{{ item.title }}</h2>
                <p class="tutoBoxDesc" v-if="item.isOpen" v-html="item.description"></p>
                <video v-if="item.isOpen && item.name" :src="item.name" class="tutoGif" autoplay muted loop playsinline></video>
                <img :src="lib + 'img/arrowicn.svg'" alt="" class="arrowicn"
                  :style="{ transform: item.isOpen ? 'rotate(90deg)' : 'rotate(0deg)' }" />
              </div>
            </div>
          </div>
          <tw-job-pages></tw-job-pages>
        </div>
      </div>
    </Transition>
`,
  hint: `
    <Transition name="fade">
      <div class="hintCard" v-show="hintCard">
        <template v-if="hintCard">
          <div class="hintCardTitle">{{ hintCard.title }}</div>
          <div class="hintCardBody">{{ hintCard.body }}</div>
          <div class="hintCardKeys">
            <span class="hintKeyCap">ENTER</span>
            <span class="hintCardKeyText">{{ hintCard.closeLabel }}</span>
            <span class="hintKeyCap hintKeyCapDim">DELETE</span>
            <span class="hintCardKeyText">{{ hintCard.neverLabel }}</span>
          </div>
        </template>
      </div>
    </Transition>
`,
  invite: `
    <div class="newInviteSide" v-show="state.requestData.show" v-if="state.requestData"
      :class="{ open: inviteReveal, 'picked-accept': invitePicked==='accept', 'picked-reject': invitePicked==='reject' }"
      :style="[state.settings.moveUI ? {'cursor': 'move', 'border': '2px dashed #ff7700'} : {}]">
      <div class="newInviteTopSide">
        <div class="newInviteTitle">
          <img :src="lib + 'img/Icon/inviteIcn.svg'" alt="" />{{state.locales['InviteRequest']}}
        </div>
        <div class="newInvitePlayer" v-if="state.defaultLogo">
          <img :src="state.defaultLogo" alt="" class="newInvitePlayerImg" />
          {{state.requestData.lobbyOwner}}
        </div>
      </div>
      <div class="newInviteBody">
        <p class="newInviteInfoText">{{state.locales['InviteText']}}</p>
        <div class="newInviteButtonList">
          <div class="newInviteButton newRejectButton" @click="denyInvite">
            <span class="iv-fill"></span>
            <div class="newInviteButtonKey">N</div>
            <span class="newInviteButtonLabel">{{state.locales['Reject']}}</span>
          </div>
          <div class="newInviteButton newAcceptButton" @click="acceptInvite">
            <span class="iv-fill"></span>
            <div class="newInviteButtonKey">Y</div>
            <span class="newInviteButtonLabel">{{state.locales['Accept']}}</span>
          </div>
        </div>
      </div>
    </div>
`,
  hud: `
    <div class="newTeamList" v-show="state.teamShow"
      :class="{ open: teamReveal || (state.settings && state.settings.moveUI) }"
      :style="[state.settings.moveUI ? {'cursor': 'move', 'border': '2px dashed #ff7700'} : {}]">
      <div class="newTeamBox" v-if="state && state.missionScoreData"
        v-for="(team, index) in state.missionScoreData.Players" :key="index"
        :style="isAway(team.playerIdentifier) ? { opacity: 0.45 } : null">
        <img :src="team.playerImage" alt="" class="newTeamProfileImg" />
        <div class="newTeamReveal">
          <div class="newTeamTextBox">
            <h2 class="newTeamText">{{team.playerName}}</h2>
            <div class="newTeamLevelBox">
              {{state.locales['Level']}} {{team.playerLevel}}<template v-if="isAway(team.playerIdentifier)"> · {{state.locales['playerAway'] || 'Away'}}</template>
            </div>
          </div>
          <div class="newTeamScoreInfo">
            <img :src="ui.scoreIcon" alt="" class="newTeamScoreInfoImg" />
            {{team.scoreAmount}}
          </div>
        </div>
      </div>
    </div>

    <div class="allScoreList" v-show="state.teamShow || (state.settings.moveUI)"
      :style="[state.settings.moveUI ? {'cursor': 'move', 'border': '2px dashed #ff7700'} : {}]">
      <div class="allScoreBox allScoreShirts" v-if="state && state.missionScoreData">
        <div class="allScoreTopSide">
          <div class="allScoreIcon">
            <svg xmlns="http://www.w3.org/2000/svg" style="width:calc(1.7708 * var(--u));height:calc(1.7708 * var(--u))" viewBox="0 0 34 34" fill="none">
              <path fill-rule="evenodd" clip-rule="evenodd"
                d="M10.5058 4.25008C10.1165 5.1439 9.91587 6.10847 9.9165 7.08341C9.9165 7.83486 10.215 8.55553 10.7464 9.08688C11.2777 9.61823 11.9984 9.91675 12.7498 9.91675H21.2498C22.0013 9.91675 22.722 9.61823 23.2533 9.08688C23.7847 8.55553 24.0832 7.83486 24.0832 7.08341C24.0832 6.07616 23.8735 5.11708 23.4938 4.25008H25.4998C26.2513 4.25008 26.972 4.54859 27.5033 5.07994C28.0347 5.6113 28.3332 6.33197 28.3332 7.08341V28.3334C28.3332 29.0849 28.0347 29.8055 27.5033 30.3369C26.972 30.8682 26.2513 31.1667 25.4998 31.1667H8.49984C7.74839 31.1667 7.02772 30.8682 6.49637 30.3369C5.96501 29.8055 5.6665 29.0849 5.6665 28.3334V7.08341C5.6665 6.33197 5.96501 5.6113 6.49637 5.07994C7.02772 4.54859 7.74839 4.25008 8.49984 4.25008H10.5058ZM16.9998 19.8334H12.7498C12.3741 19.8334 12.0138 19.9827 11.7481 20.2483C11.4824 20.514 11.3332 20.8744 11.3332 21.2501C11.3332 21.6258 11.4824 21.9861 11.7481 22.2518C12.0138 22.5175 12.3741 22.6667 12.7498 22.6667H16.9998C17.3756 22.6667 17.7359 22.5175 18.0016 22.2518C18.2672 21.9861 18.4165 21.6258 18.4165 21.2501C18.4165 20.8744 18.2672 20.514 18.0016 20.2483C17.7359 19.9827 17.3756 19.8334 16.9998 19.8334ZM21.2498 14.1667H12.7498C12.3888 14.1671 12.0415 14.3054 11.7789 14.5533C11.5163 14.8012 11.3583 15.1399 11.3372 15.5004C11.316 15.8608 11.4333 16.2158 11.665 16.4927C11.8968 16.7696 12.2255 16.9475 12.5841 16.9902L12.7498 17.0001H21.2498C21.6256 17.0001 21.9859 16.8508 22.2516 16.5851C22.5172 16.3195 22.6665 15.9591 22.6665 15.5834C22.6665 15.2077 22.5172 14.8474 22.2516 14.5817C21.9859 14.316 21.6256 14.1667 21.2498 14.1667ZM16.9998 2.83341C17.5978 2.83343 18.189 2.95961 18.7348 3.20373C19.2807 3.44785 19.7689 3.8044 20.1675 4.25008C20.7738 4.92725 21.1648 5.7985 21.2371 6.76041L21.2498 7.08341H12.7498C12.7498 6.05633 13.1139 5.11425 13.7203 4.38041L13.8322 4.25008C14.6113 3.38025 15.7418 2.83341 16.9998 2.83341Z"
                fill="currentColor" />
            </svg>
          </div>
          <div class="allScoreTextBox">
            <h2 class="allScoreText">{{state.locales['jobMission'] || 'Job tasks'}}</h2>
            <p class="allScoreDesc" v-if="state.jobProgress && state.jobProgress.label">{{state.jobProgress.label}}</p>
          </div>
        </div>

        <div class="allScoreReveal" :class="{ open: jobReveal || (state.settings && state.settings.moveUI) }">

        <transition-group name="taskRow" tag="div" class="allScoreListShirts">
          <div class="allScoreShirtBox" v-for="(data, index) in visibleJobTasks" :key="data.id ?? index">
            <div class="allScoreShirtColor" v-if="data.color" :style="{ backgroundColor: data.color }"></div>
            <h2 class="allScoreShirtText">{{ data.jobLabel }}</h2>
            <div class="allScoreShirtTaskBox">
              <svg xmlns="http://www.w3.org/2000/svg" style="width:calc(.625 * var(--u));height:calc(.625 * var(--u))" viewBox="0 0 12 12" fill="none">
                <path
                  d="M2.5 10.5C2.35833 10.5 2.23967 10.452 2.144 10.356C2.04833 10.26 2.00033 10.1413 2 10V9.5H1.5V7.5C1.5 7.35833 1.548 7.23967 1.644 7.144C1.74 7.04833 1.85867 7.00033 2 7H2.5V3.5C2.5 2.95 2.69583 2.47917 3.0875 2.0875C3.47917 1.69583 3.95 1.5 4.5 1.5C5.05 1.5 5.52083 1.69583 5.9125 2.0875C6.30417 2.47917 6.5 2.95 6.5 3.5V8.5C6.5 8.775 6.598 9.0105 6.794 9.2065C6.99 9.4025 7.22533 9.50033 7.5 9.5C7.77467 9.49967 8.01017 9.40183 8.2065 9.2065C8.40283 9.01117 8.50067 8.77567 8.5 8.5V5H8C7.85833 5 7.73967 4.952 7.644 4.856C7.54833 4.76 7.50033 4.64133 7.5 4.5V2.5H8V2C8 1.85833 8.048 1.73967 8.144 1.644C8.24 1.54833 8.35867 1.50033 8.5 1.5H9.5C9.64167 1.5 9.7605 1.548 9.8565 1.644C9.9525 1.74 10.0003 1.85867 10 2V2.5H10.5V4.5C10.5 4.64167 10.452 4.7605 10.356 4.8565C10.26 4.9525 10.1413 5.00033 10 5H9.5V8.5C9.5 9.05 9.30417 9.52083 8.9125 9.9125C8.52083 10.3042 8.05 10.5 7.5 10.5C6.95 10.5 6.47917 10.3042 6.0875 9.9125C5.69583 9.52083 5.5 9.05 5.5 8.5V3.5C5.5 3.225 5.40217 2.98967 5.2065 2.794C5.01083 2.59833 4.77533 2.50033 4.5 2.5C4.22467 2.49967 3.98933 2.59767 3.794 2.794C3.59867 2.99033 3.50067 3.22567 3.5 3.5V7H4C4.14167 7 4.2605 7.048 4.3565 7.144C4.4525 7.24 4.50033 7.35867 4.5 7.5V9.5H4V10C4 10.1417 3.952 10.2605 3.856 10.3565C3.76 10.4525 3.64133 10.5003 3.5 10.5H2.5Z"
                  fill="white" fill-opacity="0.57" />
              </svg>
              <h2 class="allScoreTaskText" v-if="data.madeCountFinish">
                {{ data.madeAmount === 0 ? '❌' : '✅ ' + data.madeAmount }}
              </h2>
              <h2 class="allScoreTaskText" v-else><span class="allScoreTaskMade">{{ data.madeAmount ?? 0 }}</span><span class="allScoreTaskTotal">/{{ data.jobCount ?? 0 }}</span></h2>

            </div>
          </div>
        </transition-group>

        <div class="jobProgressDivider" v-if="state.jobProgress"></div>

        <div class="jobProgressBox jobProgressBetween" v-if="state.jobProgress">
          <div class="jobProgressHead">
            <span class="jobProgressPhase">{{state.locales['jobProgressLabel'] || 'Progress'}}</span>
            <span class="jobProgressPct">%{{state.jobProgress.overall}}</span>
          </div>
          <div class="jobProgressBar">
            <div class="jobProgressFill" :style="{ width: state.jobProgress.overall + '%' }"></div>
          </div>
        </div>
        </div>
      </div>

      <div class="allScoreBox allScoreShirts"
        v-if="state && state.missionScoreData && state.missionScoreData.bonusJobTask && Object.keys(state.missionScoreData.bonusJobTask).length > 0">
        <div class="allScoreTopSide">
          <div class="allScoreIcon">
            <svg xmlns="http://www.w3.org/2000/svg" style="width:calc(1.7708 * var(--u));height:calc(1.7708 * var(--u))" viewBox="0 0 34 34" fill="none">
              <path fill-rule="evenodd" clip-rule="evenodd"
                d="M10.5058 4.25008C10.1165 5.1439 9.91587 6.10847 9.9165 7.08341C9.9165 7.83486 10.215 8.55553 10.7464 9.08688C11.2777 9.61823 11.9984 9.91675 12.7498 9.91675H21.2498C22.0013 9.91675 22.722 9.61823 23.2533 9.08688C23.7847 8.55553 24.0832 7.83486 24.0832 7.08341C24.0832 6.07616 23.8735 5.11708 23.4938 4.25008H25.4998C26.2513 4.25008 26.972 4.54859 27.5033 5.07994C28.0347 5.6113 28.3332 6.33197 28.3332 7.08341V28.3334C28.3332 29.0849 28.0347 29.8055 27.5033 30.3369C26.972 30.8682 26.2513 31.1667 25.4998 31.1667H8.49984C7.74839 31.1667 7.02772 30.8682 6.49637 30.3369C5.96501 29.8055 5.6665 29.0849 5.6665 28.3334V7.08341C5.6665 6.33197 5.96501 5.6113 6.49637 5.07994C7.02772 4.54859 7.74839 4.25008 8.49984 4.25008H10.5058ZM16.9998 19.8334H12.7498C12.3741 19.8334 12.0138 19.9827 11.7481 20.2483C11.4824 20.514 11.3332 20.8744 11.3332 21.2501C11.3332 21.6258 11.4824 21.9861 11.7481 22.2518C12.0138 22.5175 12.3741 22.6667 12.7498 22.6667H16.9998C17.3756 22.6667 17.7359 22.5175 18.0016 22.2518C18.2672 21.9861 18.4165 21.6258 18.4165 21.2501C18.4165 20.8744 18.2672 20.514 18.0016 20.2483C17.7359 19.9827 17.3756 19.8334 16.9998 19.8334ZM21.2498 14.1667H12.7498C12.3888 14.1671 12.0415 14.3054 11.7789 14.5533C11.5163 14.8012 11.3583 15.1399 11.3372 15.5004C11.316 15.8608 11.4333 16.2158 11.665 16.4927C11.8968 16.7696 12.2255 16.9475 12.5841 16.9902L12.7498 17.0001H21.2498C21.6256 17.0001 21.9859 16.8508 22.2516 16.5851C22.5172 16.3195 22.6665 15.9591 22.6665 15.5834C22.6665 15.2077 22.5172 14.8474 22.2516 14.5817C21.9859 14.316 21.6256 14.1667 21.2498 14.1667ZM16.9998 2.83341C17.5978 2.83343 18.189 2.95961 18.7348 3.20373C19.2807 3.44785 19.7689 3.8044 20.1675 4.25008C20.7738 4.92725 21.1648 5.7985 21.2371 6.76041L21.2498 7.08341H12.7498C12.7498 6.05633 13.1139 5.11425 13.7203 4.38041L13.8322 4.25008C14.6113 3.38025 15.7418 2.83341 16.9998 2.83341Z"
                fill="currentColor" />
            </svg>
          </div>
          <div class="allScoreTextBox">
            <h2 class="allScoreText">{{state.locales['BonusMission']}}</h2>
          </div>
        </div>
        <div class="allScoreReveal open">
          <div class="allScoreListShirts">
            <div class="allScoreShirtBox" v-for="(data, index) in state.missionScoreData.bonusJobTask" :key="index">
              <h2 class="allScoreShirtText">{{ data.jobLabel }}</h2>
              <div class="allScoreShirtTaskBox">
                <h2 class="allScoreTaskText"><span class="allScoreTaskMade">{{ data.madeAmount ?? 0 }}</span><span class="allScoreTaskTotal">/{{ data.jobCount ?? 0 }}</span></h2>
              </div>
            </div>
          </div>
        </div>
      </div>

    </div>
`,
  finish: `
    <transition name="finpop">
    <div class="finWrap" :class="{ revealed: finishReveal }" v-show="state.finishShow" v-if="state.finishJobData">
      <div class="finCard">
        <div class="finHead">
          <img :src="lib + 'img/Icon/tickallIcn.svg'" alt="" class="finHeadIcon" />
          {{ state.locales['MissionCompleted'] || 'Mission Completed' }}
        </div>

        <div class="finReveal">
          <h3 class="finTitle">{{ state.locales['YourScore'] || 'Your Score' }};</h3>
          <div class="finRow">
            <div class="finScoreBox">
              <span class="finScoreLbl">{{ state.locales['Score'] || 'Score' }}</span>
              <span class="finScoreNum">{{ state.finishJobData.historyTotalScore }}</span>
            </div>
            <div class="finScoreBox">
              <span class="finScoreLbl">{{ state.locales['BonusScore'] || 'Bonus Score' }}</span>
              <span class="finScoreNum">{{ state.finishJobData.historyBonusScore }}</span>
            </div>
          </div>

          <h3 class="finTitle">{{ state.locales['YourEarning'] || 'Your Earning' }};</h3>
          <div class="finRow">
            <div class="finEarn exp">{{ formatNumber(state.finishJobData.historyRewardXP) }}EXP</div>
            <div class="finEarn money">{{ formatNumber(state.finishJobData.historyTotalMoney) }} {{ state.serverMoneyType }}</div>
          </div>
          <div class="finEarn money finBonus">+{{ formatNumber(state.finishJobData.historyBonusMoney) }}{{ state.serverMoneyType }} ({{ state.locales['Bonus'] || 'Bonus' }})</div>
        </div>
      </div>

      <div class="finCard finReveal">
        <h3 class="finTitle">{{ state.locales['YourTeam'] || 'Your Team' }};</h3>
        <div class="finTeamList">
          <template v-for="index in 4" :key="index">
            <div class="finPlayer" v-if="state.finishJobData.historyPlayers[index - 1]">
              <img :src="state.finishJobData.historyPlayers[index - 1].playerImage" alt="" class="finAvatar" />
              <div class="finPlayerInfo">
                <span class="finPlayerName">{{ state.finishJobData.historyPlayers[index - 1].playerName }}</span>
                <span class="finLevel">{{ state.locales['Level'] || 'Level' }} {{ state.finishJobData.historyPlayers[index - 1].playerLevel }}</span>
              </div>
              <div class="finScoreBadge">
                <img :src="ui.scoreIcon" alt="" class="finBolt" />
                {{ state.finishJobData.historyPlayers[index - 1].scoreAmount }}
              </div>
            </div>
            <div class="finPlayer finEmpty" v-else>{{ state.locales['NoInformation'] || 'No Information' }}</div>
          </template>
        </div>
        <div class="finSkip"><span class="finSkipKey">E</span>{{ state.locales['SkipInformation'] || 'Skip Information' }}</div>
      </div>
    </div>
    </transition>
`,
  notify: `
    <transition-group name="nfy" tag="div" class="notifyList" @before-leave="beforeNfyLeave"
      :style="[state.settings.moveUI ?  {'cursor': 'move', 'border': '2px dashed #ff7700'} : {}]">
      <div v-for="n in notifications" :key="n.id"
        :class="['notifyBox', n.type, { expanded: n.expanded }]" @click="removeNotify(n.id)">
        <div class="notifyIcon">
          <svg v-if="n.type === 'success'" viewBox="0 0 24 24"><path fill="currentColor" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
          <svg v-else-if="n.type === 'error'" viewBox="0 0 24 24"><path fill="currentColor" d="M12 2C6.47 2 2 6.47 2 12s4.47 10 10 10 10-4.47 10-10S17.53 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/></svg>
          <svg v-else viewBox="0 0 24 24"><path fill="currentColor" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/></svg>
        </div>
        <div class="notifyBody">
          <h2 class="notifyText">{{ state.locales[n.type === 'error' ? 'Error' : n.type === 'success' ? 'Success' : 'Info'] }}</h2>
          <p class="notifySubText">{{ n.message }}</p>
        </div>
      </div>
    </transition-group>
`,
  progress: `
    <transition name="circp">
      <div v-if="progressbar > 0" class="circProgress">
        <div class="cpSpinner">
          <svg class="cpSpinRing" viewBox="0 0 44 44">
            <circle class="cpSpinTrack" cx="22" cy="22" r="18" />
            <circle class="cpSpinArc" cx="22" cy="22" r="18" :style="{ strokeDashoffset: cpDashoffset }" />
          </svg>
          <svg class="cpSpinInner" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
            <path d="M21 12a9 9 0 1 1-6.219-8.56" />
          </svg>
        </div>
        <div class="cpRight">
          <div class="cpLabel">{{ progressbarLabel || 'Loading...' }}</div>
          <div class="cpBarTrack">
            <div class="cpBarFill" :style="{ width: Math.min(Math.max(progressbar, 0), 100) + '%' }"></div>
          </div>
        </div>
      </div>
    </transition>
`,
};
